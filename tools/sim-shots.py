#!/usr/bin/env python3
"""Capture the Connect IQ Store screenshots from the simulator, automatically.

    tools/sim-shots.py            # all three, into docs/screenshots/
    tools/sim-shots.py glance     # just one

Produces the watch complete with frame and band, as the simulator draws it,
which is what the Store listing uses - not the screen-only image that
File > Save Screen Capture writes.

WHAT TOOK A WHILE TO WORK OUT

* **System Events clicks do not reach the simulator's device buttons.** They
  report success and nothing happens. Real CGEvent mouse events do work. That
  is why this uses Quartz rather than osascript for the button, and it needs
  pyobjc-framework-Quartz (see VENV below).
* **The glance cycles through three positions** - top, bottom, and centred -
  each press of the middle-left (UP) button moving to the next. Only the
  centred one is worth photographing: in the other two the simulator clips the
  band's right-hand end, so the last column looks cut off when it is not. From
  a fresh launch it takes two presses to reach centred.
* **"Glance Launch Mode" is a submenu**, not a checkbox - "Launch in Normal
  Mode" / "Launch in Glance Mode". Clicking the parent only opens it, which
  makes toggling look random.
* **The simulator persists app settings between loads.** A build with changed
  property defaults keeps the old stored values until File > Reset All App
  Data is used *while that build is loaded*. Reset before loading and it
  simply re-reads the previous defaults.
* **Save Screen Capture's dialog wedges** after other menu interactions, and
  the only reliable cure is restarting the simulator. This script avoids the
  dialog entirely by capturing the window region instead.

VENV

    python3 -m venv /tmp/qenv && /tmp/qenv/bin/pip install pyobjc-framework-Quartz
    /tmp/qenv/bin/python tools/sim-shots.py

Falls back to explaining itself if Quartz is missing.
"""

import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "screenshots")
DEVICE = "fenix9pro51mm"
CIQ = os.path.expanduser("~/Library/Application Support/Garmin/ConnectIQ")
KEY = os.path.expanduser("~/Documents/VS Code/developer_key")

# The middle-left (UP) button, in screen coordinates, with the simulator window
# at its default position and size. Measured by recording a real click.
BUTTON_UP = (69, 514)
WINDOW = (38, 37, 709, 966)          # x, y, w, h
CROP = (2, 28, 707, 936)             # drop the title bar and the status strip


def sdk():
    with open(os.path.join(CIQ, "current-sdk.cfg")) as fh:
        return fh.read().strip()


def osa(script):
    subprocess.run(["osascript", "-e", script],
                   capture_output=True, timeout=20)


def menu(item, bar):
    osa('tell application "System Events" to tell process "simulator" '
        'to set frontmost to true')
    time.sleep(0.5)
    osa(f'tell application "System Events" to tell process "simulator" to click '
        f'menu item "{item}" of menu 1 of menu bar item "{bar}" of menu bar 1')
    time.sleep(1.5)


def submenu(item, parent, bar):
    osa('tell application "System Events" to tell process "simulator" '
        'to set frontmost to true')
    time.sleep(0.5)
    osa(f'tell application "System Events" to tell process "simulator" to click '
        f'menu item "{item}" of menu 1 of menu item "{parent}" of menu 1 of '
        f'menu bar item "{bar}" of menu bar 1')
    time.sleep(1.5)


def click(x, y):
    """A real mouse event. System Events clicks do not reach the buttons."""
    try:
        import Quartz
    except ImportError:
        sys.exit("needs pyobjc-framework-Quartz — see the VENV note at the top")
    pt = Quartz.CGPointMake(float(x), float(y))
    for kind, btn in ((Quartz.kCGEventMouseMoved, 0),
                      (Quartz.kCGEventLeftMouseDown, Quartz.kCGMouseButtonLeft),
                      (Quartz.kCGEventLeftMouseUp, Quartz.kCGMouseButtonLeft)):
        Quartz.CGEventPost(Quartz.kCGHIDEventTap,
                           Quartz.CGEventCreateMouseEvent(None, kind, pt, btn))
        time.sleep(0.12)
    time.sleep(2.0)


def shot(name):
    from PIL import Image
    raw = os.path.join("/tmp", f"simshot-{os.getpid()}.png")
    x, y, w, h = WINDOW
    subprocess.run(["screencapture", "-x", f"-R{x},{y},{w},{h}", raw], check=True)
    os.makedirs(OUT, exist_ok=True)
    dest = os.path.join(OUT, name)
    Image.open(raw).crop(CROP).save(dest)
    os.remove(raw)
    print(f"  wrote {os.path.relpath(dest, ROOT)}")


def build(prg, extra_sed=None):
    src = os.path.join(ROOT, "resources", "TempWidgetApResources.xml")
    backup = None
    if extra_sed:
        # Binary, not text: this file has CRLF line endings and a text-mode
        # rewrite silently converts the whole thing to LF, which shows up as
        # every line changed in the diff.
        backup = open(src, "rb").read()
        text = backup
        for old, new in extra_sed:
            o, n = old.encode(), new.encode()
            assert text.count(o) == 1, f"pattern not unique: {old}"
            text = text.replace(o, n)
        open(src, "wb").write(text)
    try:
        subprocess.run([f"{sdk()}/bin/monkeyc", "-o", prg, "-f",
                        os.path.join(ROOT, "monkey.jungle"), "-y", KEY,
                        "-d", DEVICE, "-l", "1"], check=True,
                       capture_output=True)
    finally:
        if backup is not None:
            open(src, "wb").write(backup)


def restart_sim():
    subprocess.run(["pkill", "-f", "monkeydo"], capture_output=True)
    subprocess.run(["pkill", "-f", "MacOS/simulator"], capture_output=True)
    time.sleep(5)
    subprocess.Popen([f"{sdk()}/bin/connectiq"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(20)


def load(prg):
    subprocess.run(["pkill", "-f", "monkeydo"], capture_output=True)
    time.sleep(2)
    subprocess.Popen([f"{sdk()}/bin/monkeydo", prg, DEVICE],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(15)


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    normal = f"/tmp/simshot-normal-{os.getpid()}.prg"
    internal = f"/tmp/simshot-internal-{os.getpid()}.prg"

    print("building…")
    build(normal)
    # Slot 0 on the internal sensor, so the third shot needs no paging - the
    # device buttons cannot page the main view reliably.
    build(internal, [
        ('<property id="T0ID" type="number">0</property>',
         '<property id="T0ID" type="number">-1</property>'),
        ('<property id="T0Label" type="string">Tempe1</property>',
         '<property id="T0Label" type="string">Internal</property>'),
    ])

    if which in ("all", "glance"):
        print("glance…")
        restart_sim()
        submenu("Launch in Glance Mode", "Glance Launch Mode", "Settings")
        load(normal)
        click(*BUTTON_UP)          # two presses from a fresh launch
        click(*BUTTON_UP)          # lands on the centred, unclipped position
        shot("1-glance.png")

    if which in ("all", "full"):
        print("full view…")
        restart_sim()
        submenu("Launch in Normal Mode", "Glance Launch Mode", "Settings")
        load(normal)
        menu("Reset All App Data", "File")   # must run with the build loaded
        load(normal)
        shot("2-full.png")

    if which in ("all", "internal"):
        print("internal sensor…")
        restart_sim()
        submenu("Launch in Normal Mode", "Glance Launch Mode", "Settings")
        load(internal)
        menu("Reset All App Data", "File")
        load(internal)
        shot("3-internal.png")

    for p in (normal, internal):
        if os.path.exists(p):
            os.remove(p)
    print("done — check the images before using them")


if __name__ == "__main__":
    main()
