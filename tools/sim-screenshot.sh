#!/usr/bin/env bash
#
# Put TempeWidget into the simulator on a fenix 9 Pro 51mm, ready for Store
# screenshots, and capture them if macOS will let us.
#
#   tools/sim-screenshot.sh                 # fenix9pro51mm (the Store target)
#   tools/sim-screenshot.sh fenix6          # some other device
#
# Shots land in docs/screenshots/.
#
# WHY THIS IS NOT FULLY AUTOMATIC
#
# Two macOS permissions stand in the way and only a human can grant them:
#
#   * Screen Recording  - without it `screencapture` returns "could not create
#                         image from display" and writes nothing.
#   * Accessibility     - without it osascript hangs on its own consent prompt
#                         rather than failing, so driving the simulator's
#                         File > Save Screenshot menu is worse than useless.
#
# So this script does every part that can be automated - build, launch, load,
# and get the app into a state worth photographing - and then either captures
# for you or tells you the exact clicks. The simulator's own File > Save
# Screenshot needs no permission at all and gives the cleanest output: just the
# device screen, no window chrome. That is the recommended route.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVICE="${1:-fenix9pro51mm}"
OUT="$ROOT/docs/screenshots"
CIQ="${CIQ_HOME:-$HOME/Library/Application Support/Garmin/ConnectIQ}"
KEY="${CIQ_DEV_KEY:-$HOME/Documents/VS Code/developer_key}"
SDK="$(tr -d '\n' < "$CIQ/current-sdk.cfg")"
PRG="$(mktemp -d)/$DEVICE.prg"

[ -d "$CIQ/Devices/$DEVICE" ] || { echo "No device definition for $DEVICE" >&2; exit 1; }
mkdir -p "$OUT"

echo "== building $DEVICE =="
"$SDK/bin/monkeyc" -o "$PRG" -f "$ROOT/monkey.jungle" -y "$KEY" -d "$DEVICE" -l 1 \
    || { echo "build failed" >&2; exit 1; }
echo "  ok"

echo
echo "== restarting the simulator =="
# Killing only MonkeyDoDeux or the shell transport leaves the simulator alive
# but unable to accept another load, so take the whole thing down.
pkill -f "MacOS/simulator" 2>/dev/null
sleep 4
nohup "$SDK/bin/connectiq" >/dev/null 2>&1 &
sleep 18
pgrep -f "MacOS/simulator" >/dev/null || { echo "simulator did not start" >&2; exit 1; }
echo "  up"

echo
echo "== loading the widget =="
# monkeydo blocks for as long as the app runs, so background it.
nohup "$SDK/bin/monkeydo" "$PRG" "$DEVICE" >"$OUT/.monkeydo.log" 2>&1 &
sleep 12
echo "  loaded ($DEVICE)"

# Does this machine let us capture at all?
probe="$(mktemp).png"
screencapture -x "$probe" 2>/dev/null
if [ -s "$probe" ]; then CAPTURE=yes; else CAPTURE=no; fi
rm -f "$probe"

cat <<'EOF'

================================================================
The widget is running. Connect IQ starts widget apps in GLANCE
mode, so what is on screen now is the glance view - the one that
changed most in 1.0.0 and the one nobody has looked at yet.

Three shots are worth having:

  1. glance        - as it stands right now
  2. full view     - press Enter/Start to open it from the glance
  3. internal slot - swipe/page to the slot whose ID is -1, which
                     shows "--" for min and max, so the caveat in
                     the description has a picture to go with it

Page between slots with the up/down arrows or Enter.
================================================================
EOF

if [ "$CAPTURE" = yes ]; then
    cat <<EOF

Screen Recording is granted, so this can capture for you.
For each shot: get the screen how you want it, then run

    screencapture -w "$OUT/1-glance.png"

and click the simulator window. Repeat for 2-full.png and
3-internal.png.
EOF
else
    cat <<EOF

Screen Recording is NOT granted - screencapture writes nothing.
Two options:

  a) Use the simulator's own menu, which needs no permission and
     gives the cleanest image (device screen only, no chrome):

         File > Save Screenshot

     Save into:  $OUT
     Name them:  1-glance.png, 2-full.png, 3-internal.png

  b) Grant the permission once, then rerun this script:

         System Settings > Privacy & Security > Screen Recording
         enable the app running Claude Code (Terminal/iTerm/VS Code)
         then restart that app

(a) is recommended. Garmin wants the device screen, and the menu
gives exactly that, already cropped.
EOF
fi

cat <<EOF

The simulator is left running. When you are done:

    pkill -f "MacOS/simulator"

Then: tools/release-preflight.sh
EOF
