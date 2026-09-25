#!/usr/bin/env bash
#
# Build the "TempeWidget Beta" store export: the same code, under its own app
# id and name, so a release candidate can be installed from the Connect IQ
# Store on a real watch without touching the live TempeWidget listing or the
# 1,000+ people who have it.
#
#   tools/build-beta.sh            # -> export/TempeWidget-Beta.iq
#
# The beta app id below is permanent. Every beta upload must use the same id
# or the Store treats it as a new app, and the watch as a new install with its
# own settings. The real app id in manifest.xml is never modified: the build
# runs from a patched temporary copy of the project.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CIQ="${CIQ_HOME:-$HOME/Library/Application Support/Garmin/ConnectIQ}"
KEY="${CIQ_DEV_KEY:-$HOME/Documents/VS Code/developer_key}"
SDK="$(tr -d '\n' < "$CIQ/current-sdk.cfg")"

BETA_ID="7c1d9a2e-5b64-4f0e-9d3a-2e8f6b1c4a57"
BETA_NAME="TempeWidget Beta"

LIVE_ID="$(sed -n 's/.*<iq:application[^>]* id="\([^"]*\)".*/\1/p' "$ROOT/manifest.xml")"
[ -n "$LIVE_ID" ] || { echo "could not read the app id from manifest.xml" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -R "$ROOT/source" "$ROOT/resources" "$ROOT"/resources-icon* "$ROOT/manifest.xml" "$ROOT/monkey.jungle" "$TMP/"

sed -i '' "s/id=\"$LIVE_ID\"/id=\"$BETA_ID\"/" "$TMP/manifest.xml"
sed -i '' "s|<string id=\"AppName\" scope=\"Background\">TempeWidget</string>|<string id=\"AppName\" scope=\"Background\">$BETA_NAME</string>|" "$TMP/resources/strings/strings.xml"
grep -q "$BETA_ID" "$TMP/manifest.xml" || { echo "manifest id patch failed" >&2; exit 1; }
grep -q "$BETA_NAME" "$TMP/resources/strings/strings.xml" || { echo "app name patch failed" >&2; exit 1; }

mkdir -p "$ROOT/export"
OUT="$ROOT/export/TempeWidget-Beta.iq"
echo "== building $BETA_NAME ($BETA_ID) =="
( cd "$TMP" && "$SDK/bin/monkeyc" -e -w -o "$OUT" -f monkey.jungle -y "$KEY" -l 1 ) 2>&1 | grep -v "^$" | tail -5
ls -la "$OUT"
