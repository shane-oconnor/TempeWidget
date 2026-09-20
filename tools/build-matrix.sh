#!/usr/bin/env bash
#
# Build TempeWidget against every product in manifest.xml, at both type-check
# levels, then produce the store .iq export.
#
# This cannot run in hosted CI: the compiler needs the per-device definitions
# under ~/Library/Application Support/Garmin/ConnectIQ/Devices, and those are
# only downloadable through the SDK Manager after a Garmin account login.
# Run it locally before tagging a release.
#
# Usage:
#   tools/build-matrix.sh              # every product in the manifest
#   tools/build-matrix.sh fenix9pro51mm epix2   # just these
#
set -uo pipefail

CIQ="${CIQ_HOME:-$HOME/Library/Application Support/Garmin/ConnectIQ}"
KEY="${CIQ_DEV_KEY:-$HOME/Documents/VS Code/developer_key}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

[ -f "$CIQ/current-sdk.cfg" ] || { echo "No current-sdk.cfg under $CIQ" >&2; exit 1; }
SDK="$(tr -d '\n' < "$CIQ/current-sdk.cfg")"
MONKEYC="$SDK/bin/monkeyc"
[ -x "$MONKEYC" ] || { echo "monkeyc not executable at $MONKEYC" >&2; exit 1; }
[ -f "$KEY" ] || { echo "Developer key not found at $KEY (set CIQ_DEV_KEY)" >&2; exit 1; }

if [ "$#" -gt 0 ]; then
    products=("$@")
else
    products=()
    while IFS= read -r p; do products+=("$p"); done < <(
        grep -o 'iq:product id="[^"]*"' "$ROOT/manifest.xml" | sed 's/.*id="//; s/"//')
fi

echo "SDK:      $SDK"
echo "Products: ${#products[@]}"
echo

failed=()
total_warns=0
level_warns=0
for level in 1 2; do
    level_warns=0
    echo "== type-check level $level =="
    for p in "${products[@]}"; do
        if [ ! -d "$CIQ/Devices/$p" ]; then
            echo "  SKIP  $p (no device definition installed)"
            continue
        fi
        if "$MONKEYC" -w -o "$OUT/$p.prg" -f "$ROOT/monkey.jungle" -y "$KEY" \
                      -d "$p" -l "$level" >"$OUT/$p.log" 2>&1; then
            warns=$(grep -c WARNING "$OUT/$p.log")
            if [ "$warns" -gt 0 ]; then
                echo "  ok    $p  ($warns warning(s))"
                total_warns=$((total_warns + warns))
                level_warns=$((level_warns + warns))
            else
                echo "  ok    $p"
            fi
        else
            echo "  FAIL  $p"
            sed 's/^/          /' "$OUT/$p.log"
            failed+=("$p@L$level")
        fi
    done
    echo "  level $level: $level_warns warning(s) across ${#products[@]} products"
    echo
done

echo "== store export =="
if "$MONKEYC" -e -o "$OUT/TempeWidget.iq" -f "$ROOT/monkey.jungle" -y "$KEY" \
              2>&1 | tee "$OUT/export.log" | tail -3; then
    mkdir -p "$ROOT/export" && cp "$OUT/TempeWidget.iq" "$ROOT/export/"
    echo "  wrote export/TempeWidget.iq"
else
    echo "  FAIL  store export"
    failed+=("export")
fi

echo
echo
if [ "${#failed[@]}" -gt 0 ]; then
    echo "FAILED: ${failed[*]}"
    exit 1
fi
echo "All builds passed."
