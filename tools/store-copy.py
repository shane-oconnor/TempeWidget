#!/usr/bin/env python3
"""Extract the Connect IQ Store fields from docs/store-listing.md.

The listing copy is written and reviewed in the repo, not typed into the
portal, so that what went live is versioned alongside the release. This pulls
the three hand-written fields back out so they can be pasted or typed into the
portal verbatim, with no chance of transcription drift.

    python3 tools/store-copy.py                 # show all three, with lengths
    python3 tools/store-copy.py version         # just one, raw, for piping
    python3 tools/store-copy.py --write DIR     # one .txt per field in DIR

Each field is the first fenced code block under its numbered heading. The
headings are matched loosely on their number so the wording can change without
breaking this.
"""

import os
import re
import sys

FIELDS = {
    "version": r"^##\s*1\.",
    "description": r"^##\s*2\.",
    "whatsnew": r"^##\s*3\.",
}

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LISTING = os.path.join(ROOT, "docs", "store-listing.md")

# Garmin does not document these and they have not been read off the portal
# yet, so treat them as a prompt to look rather than a rule. The real limit is
# the maxlength on each input; when the portal is next open, check it and
# replace this. Lengths are always reported so a near-miss is visible.
LIMITS_UNVERIFIED = {"version": None, "description": None, "whatsnew": None}


def extract(text, heading_re):
    """First fenced block after the heading, or None."""
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if re.match(heading_re, line):
            start = i
            break
    if start is None:
        return None

    fence = None
    body = []
    for line in lines[start + 1:]:
        if line.startswith("```"):
            if fence is None:
                fence = True
                continue
            return "\n".join(body)
        if line.startswith("## "):          # next section, no block found
            return None
        if fence:
            body.append(line)
    return None


def load():
    if not os.path.exists(LISTING):
        sys.exit(f"not found: {LISTING}")
    text = open(LISTING, encoding="utf-8").read()
    out = {}
    for name, pattern in FIELDS.items():
        value = extract(text, pattern)
        if value is None:
            sys.exit(f"could not find the {name} block in docs/store-listing.md")
        out[name] = value.strip("\n")
    return out


def main():
    args = sys.argv[1:]
    fields = load()

    if args and args[0] == "--write":
        if len(args) < 2:
            sys.exit("--write needs a directory")
        d = args[1]
        os.makedirs(d, exist_ok=True)
        for name, value in fields.items():
            path = os.path.join(d, f"{name}.txt")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(value + "\n")
            print(f"wrote {path}  ({len(value)} chars)")
        return

    if args:
        name = args[0]
        if name not in fields:
            sys.exit(f"unknown field {name!r}; expected one of {', '.join(FIELDS)}")
        print(fields[name])
        return

    problems = []
    for name, value in fields.items():
        limit = LIMITS_UNVERIFIED.get(name)
        flag = ""
        if limit is not None and len(value) > limit:
            flag = f"  OVER {limit}"
            problems.append(name)
        print(f"\n===== {name}  [{len(value)} chars]{flag} " + "=" * 20)
        print(value)

    # The version string is the one most likely to be stale, so say what it is
    # rather than leaving it buried in the dump above.
    print("\n" + "=" * 60)
    print(f"version field  -> {fields['version']!r}")
    first = fields["whatsnew"].splitlines()[0] if fields["whatsnew"] else ""
    print(f"what's new top -> {first!r}")
    vnum = fields["version"].split()[0]
    if not fields["whatsnew"].startswith(vnum):
        print(f"\nNOTE: the What's New entry does not start with {vnum!r}, the "
              "number in the version field. Check they agree before submitting.")
    if problems:
        sys.exit(f"\n{', '.join(problems)} exceeds a recorded field limit")


if __name__ == "__main__":
    main()
