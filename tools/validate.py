#!/usr/bin/env python3
"""Static checks for the TempeWidget project.

Runs without the Connect IQ SDK, so it works on a hosted CI runner.
The device definitions the compiler needs are only available behind a
Garmin account login, so an actual build cannot run here -- use
tools/build-matrix.sh on a machine with the SDK installed for that.

What this catches is the class of defect the compiler stays quiet about:
resource references that point at nothing, settings wired to nothing, and
debug output that would ship enabled.
"""

import os
import re
import sys
import glob
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def rel(path):
    return os.path.relpath(path, ROOT)


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def resource_files():
    return sorted(glob.glob(os.path.join(ROOT, "resources", "**", "*.xml"), recursive=True))


def source_files():
    return sorted(glob.glob(os.path.join(ROOT, "source", "*.mc")))


# ---------------------------------------------------------------- 1. markers

def check_conflict_markers():
    targets = [os.path.join(ROOT, ".gitignore"), os.path.join(ROOT, "manifest.xml"),
               os.path.join(ROOT, "monkey.jungle")]
    targets += resource_files() + source_files()
    pattern = re.compile(r"^(<{7}|={7}|>{7})(\s|$)")
    for path in targets:
        if not os.path.exists(path):
            continue
        for n, line in enumerate(read(path).splitlines(), 1):
            if pattern.match(line):
                err(f"{rel(path)}:{n}: unresolved merge-conflict marker")


# ------------------------------------------------------------------- 2. xml

def check_xml_wellformed():
    for path in [os.path.join(ROOT, "manifest.xml")] + resource_files():
        try:
            ET.parse(path)
        except ET.ParseError as exc:
            err(f"{rel(path)}: not well-formed XML: {exc}")


# -------------------------------------------------------------- 3. manifest

def check_manifest_products():
    path = os.path.join(ROOT, "manifest.xml")
    ids = re.findall(r'<iq:product\s+id="([^"]+)"', read(path))
    seen = {}
    for pid in ids:
        if pid in seen:
            err(f"manifest.xml: duplicate <iq:product id=\"{pid}\">")
        seen[pid] = True
    if not ids:
        err("manifest.xml: no <iq:product> entries found")
    return ids


# -------------------------------------------------------------- 4. strings

def declared_strings():
    path = os.path.join(ROOT, "resources", "strings", "strings.xml")
    if not os.path.exists(path):
        err("resources/strings/strings.xml: missing")
        return {}
    return {m.group(1): path for m in re.finditer(r'<string\s+id="([^"]+)"', read(path))}


def check_string_references(declared):
    used = set()
    # manifest.xml references @Strings.AppName, so it counts as a consumer.
    for path in resource_files() + [os.path.join(ROOT, "manifest.xml")]:
        for m in re.finditer(r"@Strings\.([A-Za-z0-9_]+)", read(path)):
            used.add(m.group(1))
            if m.group(1) not in declared:
                err(f"{rel(path)}: @Strings.{m.group(1)} is referenced but not declared "
                    f"in resources/strings/strings.xml")
    # Monkey C reaches a string as Rez.Strings.Name, which is just as much a
    # consumer as a resource file's @Strings.Name.
    for path in source_files():
        for m in re.finditer(r"Rez\.Strings\.([A-Za-z0-9_]+)", read(path)):
            used.add(m.group(1))
            if m.group(1) not in declared:
                err(f"{rel(path)}: Rez.Strings.{m.group(1)} is referenced but not declared "
                    f"in resources/strings/strings.xml")
    for name in sorted(set(declared) - used):
        warn(f"resources/strings/strings.xml: string '{name}' is declared but never referenced")


# ----------------------------------------------------------- 5/6. properties

def declared_properties():
    path = os.path.join(ROOT, "resources", "TempWidgetApResources.xml")
    if not os.path.exists(path):
        err("resources/TempWidgetApResources.xml: missing")
        return {}
    return {m.group(1): path for m in re.finditer(r'<property\s+id="([^"]+)"', read(path))}


def check_settings_properties(declared):
    path = os.path.join(ROOT, "resources", "TempWidgetApResources.xml")
    if not os.path.exists(path):
        return
    for m in re.finditer(r"@Properties\.([A-Za-z0-9_]+)", read(path)):
        if m.group(1) not in declared:
            err(f"resources/TempWidgetApResources.xml: settings entry references "
                f"@Properties.{m.group(1)}, which is not declared as a <property>")


def strip_comments(text):
    """Remove // and /* */ comments so dead code is not mistaken for live code."""
    out = []
    i, n = 0, len(text)
    while i < n:
        two = text[i:i + 2]
        if two == "//":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append("\n" * text.count("\n", i, j))
            i = j
        elif two == "/*":
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("\n" * text.count("\n", i, j))
            i = j
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:min(j + 1, n)])
            i = j + 1
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def property_read_patterns():
    """Regexes matching the property keys the source actually reads.

    Keys are often built by concatenation -- getProp("T"+i+"ID", ...) covers
    T0ID, T1ID and T2ID -- so a non-literal fragment becomes a wildcard.
    """
    call = re.compile(r"(?<!function )\b(?:getProp|Application\.Properties\.getValue"
                      r"|Properties\.getValue)\s*\(")
    patterns = []
    for path in source_files():
        text = strip_comments(read(path))
        for m in call.finditer(text):
            # Take the first argument: everything up to the top-level comma or ')'.
            i, depth, arg = m.end(), 0, []
            while i < len(text):
                ch = text[i]
                if ch == '"':
                    j = i + 1
                    while j < len(text) and text[j] != '"':
                        j += 2 if text[j] == "\\" else 1
                    arg.append(text[i:j + 1])
                    i = j + 1
                    continue
                if ch in "([":
                    depth += 1
                elif ch in ")]":
                    if depth == 0:
                        break
                    depth -= 1
                elif ch == "," and depth == 0:
                    break
                arg.append(ch)
                i += 1
            expr = "".join(arg).strip()
            frags = re.split(r'"([^"]*)"', expr)
            # Odd indices are string literals, even indices are the code between them.
            regex = ""
            for idx, frag in enumerate(frags):
                if idx % 2:
                    regex += re.escape(frag)
                elif frag.strip(" +\t\n"):
                    regex += ".+"
            # A key with no string literal in it at all is fully dynamic and
            # tells us nothing -- treating it as a wildcard would silently
            # disable this check, so skip it instead.
            if regex and '"' in expr:
                patterns.append(re.compile("^" + regex + "$"))
    return patterns


def check_properties_are_read(declared):
    patterns = property_read_patterns()
    for name in sorted(declared):
        if not any(p.match(name) for p in patterns):
            err(f"resources/TempWidgetApResources.xml: property '{name}' is declared "
                f"(and offered in the settings menu) but no source file ever reads it")


# ------------------------------------------------------------- 7. debug logs

def check_println_gated():
    """CLAUDE.md: debug output must be wrapped in `if (fDbg)`.

    A println inside a catch block is exempt. Reporting a failure that was
    actually caught is not debug logging, and silencing it behind a flag the
    user has switched off is how a real fault goes unnoticed.
    """
    for path in source_files():
        text = strip_comments(read(path))
        # Walk the file tracking, for each open brace, whether the block it
        # opened was guarded by a condition mentioning fDbg.
        guarded = []
        line = 1
        i = 0
        while i < len(text):
            ch = text[i]
            if ch == "\n":
                line += 1
            elif ch == "{":
                head = text[max(0, i - 200):i]
                if re.search(r"catch\s*\([^()]*\)\s*$", head):
                    guarded.append(True)
                else:
                    guarded.append("fDbg" in head.rsplit(")", 1)[0].rsplit("if", 1)[-1]
                                   if "if" in head else False)
            elif ch == "}":
                if guarded:
                    guarded.pop()
            elif text.startswith("System.println", i):
                if not any(guarded):
                    warn(f"{rel(path)}:{line}: System.println is not inside an `if (fDbg)` block")
                i += len("System.println")
                continue
            i += 1


# ------------------------------------------------------- 8. launcher icons

def png_size(path):
    """Width and height from a PNG IHDR, without needing Pillow in CI."""
    import struct
    with open(path, "rb") as fh:
        head = fh.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", head[16:24])


def check_launcher_icons(products):
    """Per-device icon folders must hold an icon of the size they claim, and
    monkey.jungle must map them to products that actually exist."""
    jungle = os.path.join(ROOT, "monkey.jungle")
    text = read(jungle) if os.path.exists(jungle) else ""

    on_disk = set()
    for name in sorted(os.listdir(ROOT)):
        m = re.fullmatch(r"resources-icon(\d+)", name)
        if not m:
            continue
        size = int(m.group(1))
        on_disk.add(name)
        icon = os.path.join(ROOT, name, "drawables", "Therm2d.png")
        if not os.path.exists(icon):
            err(f"{name}/drawables/Therm2d.png: missing")
            continue
        got = png_size(icon)
        if got is None:
            err(f"{name}/drawables/Therm2d.png: not a PNG")
        elif got != (size, size):
            err(f"{name}/drawables/Therm2d.png is {got[0]}x{got[1]}, but the "
                f"folder name promises {size}x{size}")
        dx = os.path.join(ROOT, name, "drawables", "drawables.xml")
        if not os.path.exists(dx):
            err(f"{name}/drawables/drawables.xml: missing")
        elif 'id="LauncherIcon"' not in read(dx):
            err(f"{name}/drawables/drawables.xml: does not define LauncherIcon")

    referenced = set()
    for prod, folder in re.findall(
            r"^(\S+)\.resourcePath\s*=.*?;(resources-icon\d+)\s*$",
            text, re.M):
        referenced.add(folder)
        if prod not in products:
            err(f"monkey.jungle: resourcePath set for '{prod}', which is not "
                f"an <iq:product> in manifest.xml")
        if folder not in on_disk:
            err(f"monkey.jungle: '{prod}' points at {folder}/, which does not exist")

    for folder in sorted(on_disk - referenced):
        warn(f"{folder}/ exists but monkey.jungle maps no product to it")


BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "baseline.txt")


def load_baseline():
    """Findings that are known, filed and deliberately deferred.

    Keeping them out of the failure set means a red build always means
    something new, rather than something already on the issue tracker.
    """
    if not os.path.exists(BASELINE):
        return []
    out = []
    for line in read(BASELINE).splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            out.append(line)
    return out


def main():
    check_conflict_markers()
    check_xml_wellformed()
    products = check_manifest_products()

    declared_str = declared_strings()
    check_string_references(declared_str)

    declared_prop = declared_properties()
    check_settings_properties(declared_prop)
    check_properties_are_read(declared_prop)

    check_println_gated()
    check_launcher_icons(set(products))

    baseline = load_baseline()
    matched = set()

    def baselined(msg):
        for entry in baseline:
            if entry in msg:
                matched.add(entry)
                return True
        return False

    known = [e for e in errors if baselined(e)]
    fresh = [e for e in errors if e not in known]
    stale = [b for b in baseline if b not in matched]

    print("TempeWidget validation")
    print(f"  {len(products)} products in manifest.xml")
    print(f"  {len(declared_prop)} properties, {len(declared_str)} strings")
    print()

    for w in warnings:
        print(f"warning: {w}")
    for k in known:
        print(f"known:   {k}")
    for e in fresh:
        print(f"error:   {e}")
    for b in stale:
        print(f"error:   tools/baseline.txt: entry no longer matches anything "
              f"and should be removed: {b}")

    print()
    if fresh or stale:
        print(f"FAILED: {len(fresh) + len(stale)} new error(s), "
              f"{len(known)} known, {len(warnings)} warning(s)")
        return 1
    print(f"OK: 0 new errors, {len(known)} known, {len(warnings)} warning(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
