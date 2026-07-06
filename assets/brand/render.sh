#!/usr/bin/env bash
# Re-render every brand PNG from its HTML source so the design never drifts.
#
# Requires a Chromium/Chrome binary. Set CHROME to override autodetection, e.g.
#   CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ./render.sh
#
# Each asset is defined as:  name  width  height  scale
set -euo pipefail
cd "$(dirname "$0")"

CHROME="${CHROME:-}"
if [[ -z "$CHROME" ]]; then
  for c in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "$(command -v google-chrome || true)" \
    "$(command -v chromium || true)" \
    "$(command -v chromium-browser || true)"; do
    [[ -n "$c" && -x "$c" ]] && CHROME="$c" && break
  done
fi
[[ -z "$CHROME" ]] && { echo "No Chrome/Chromium found. Set \$CHROME."; exit 1; }

shot() { # name width height scale
  "$CHROME" --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
    --force-device-scale-factor="$4" --window-size="$2,$3" \
    --default-background-color=00000000 --screenshot="$1.png" "$1.html"
  echo "  rendered $1.png (${2}x${3} @${4}x)"
}

shot logomark            512 512  2
shot logomark-paper      512 512  2
shot logo-horizontal    1000 300  2
shot logo-horizontal-dark 1000 300 2
shot logo-stacked        600 640  2
shot avatar              512 512  2
shot avatar-clay         512 512  2
shot favicon             256 256  2
shot social-preview     1280 640  2
shot og-card            1200 630  2
shot x-banner           1500 500  2
shot readme-hero        1280 340  2
echo "done."
