#!/usr/bin/env bash
#
# Everything that can be checked mechanically before uploading to the Connect
# IQ Store. Run this first; it is cheap and it fails loudly.
#
# It deliberately does NOT build. A build takes ten minutes and this needs to
# be runnable repeatedly while preparing the listing. What it does instead is
# prove the existing export/TempeWidget.iq is newer than every source file it
# was built from, which is the thing that actually goes wrong.
#
#   tools/release-preflight.sh
#
# Exit code 0 means nothing mechanical is blocking. It cannot tell you whether
# the screenshots are any good or whether the glance view looks right; those
# are in docs/store-listing.md under "Before submitting".

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=1; }
note() { printf '  --    %s\n' "$1"; }

echo "== repository =="
branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" = "master" ] && ok "on master" || bad "on '$branch', not master"

if [ -z "$(git status --porcelain)" ]; then
    ok "working tree clean"
else
    bad "working tree dirty:"
    git status --short | sed 's/^/          /'
fi

git fetch -q origin 2>/dev/null
if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/master 2>/dev/null)" ]; then
    ok "master matches origin"
else
    bad "master differs from origin/master — push before releasing"
fi

echo
echo "== validation =="
if python3 tools/validate.py >/tmp/preflight-validate.$$ 2>&1; then
    warns=$(grep -c '^warning:' /tmp/preflight-validate.$$ || true)
    if [ "$warns" -eq 0 ]; then ok "validate.py: 0 errors, 0 warnings"
    else ok "validate.py passed with $warns warning(s)"; fi
else
    bad "validate.py failed:"
    sed 's/^/          /' /tmp/preflight-validate.$$
fi
rm -f /tmp/preflight-validate.$$

echo
echo "== the artifact =="
IQ="export/TempeWidget.iq"
if [ ! -f "$IQ" ]; then
    bad "$IQ does not exist — run tools/build-matrix.sh"
else
    size=$(stat -f%z "$IQ")
    ok "$IQ present (${size} bytes)"
    # The .iq is gitignored, so git cannot tell us whether it is current. Compare
    # its mtime against everything it is built from instead.
    newer=$(find source resources resources-icon* manifest.xml monkey.jungle \
                 -type f -newer "$IQ" 2>/dev/null | head -5)
    if [ -n "$newer" ]; then
        bad "these are newer than the .iq — it is stale, rebuild:"
        echo "$newer" | sed 's/^/          /'
    else
        ok "newer than every source, resource and manifest file"
    fi
fi

products=$(grep -c 'iq:product id=' manifest.xml)
note "manifest declares $products products"

echo
echo "== listing copy (docs/store-listing.md) =="
if python3 tools/store-copy.py >/tmp/preflight-copy.$$ 2>&1; then
    grep -E '^(version field|what.s new top)' /tmp/preflight-copy.$$ | sed 's/^/  /'
    grep -E '^===== ' /tmp/preflight-copy.$$ | sed 's/^===== /  /; s/ =*$//'
    ok "all three fields extracted"
else
    bad "could not extract the listing copy:"
    sed 's/^/          /' /tmp/preflight-copy.$$
fi
if grep -q 'NOTE: the What' /tmp/preflight-copy.$$ 2>/dev/null; then
    bad "version field and What's New disagree on the version number"
fi
rm -f /tmp/preflight-copy.$$

echo
echo "== still needs a human =="
grep -n '^- \[ \]' docs/store-listing.md | sed 's/^[0-9]*:- \[ \] /  * /' | cut -c1-96

echo
if [ "$fail" -ne 0 ]; then
    echo "PREFLIGHT FAILED — fix the above before uploading."
    exit 1
fi
echo "Preflight passed. Nothing mechanical is blocking the upload."
