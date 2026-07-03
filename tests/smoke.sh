#!/usr/bin/env bash
# Simple smoke tests for yt-dlp-media-tools.
# No network, no yt-dlp/ffmpeg required — safe to run in CI.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

pass=0
fail=0
ok()  { printf "  PASS  %s\n" "$1"; pass=$((pass + 1)); }
bad() { printf "  FAIL  %s\n" "$1"; fail=$((fail + 1)); }

# 1) Scripts have valid syntax
for f in yt-dlp-media-tools.sh install.sh; do
  if bash -n "$f" 2>/dev/null; then ok "syntax: $f"; else bad "syntax: $f"; fi
done

# 2) --version prints a version line
ver_out="$(bash yt-dlp-media-tools.sh --version 2>/dev/null)"
if printf '%s' "$ver_out" | grep -q "yt-dlp-media-tools v"; then
  ok "--version prints a version"
else
  bad "--version output was: $ver_out"
fi

# 3) --help mentions usage
help_out="$(bash yt-dlp-media-tools.sh --help 2>/dev/null)"
if printf '%s' "$help_out" | grep -qi "usage"; then
  ok "--help mentions usage"
else
  bad "--help did not mention usage"
fi

# 4) URL validation accepts good links and rejects bad ones
eval "$(awk '/^is_valid_url\(\)/{p=1} p{print} p&&/^}$/{exit}' yt-dlp-media-tools.sh)"
check_url() { # $1 = url, $2 = expected (0 = accept, 1 = reject)
  if is_valid_url "$1"; then got=0; else got=1; fi
  if [ "$got" -eq "$2" ]; then ok "url: $1"; else bad "url: $1 (wanted $2, got $got)"; fi
}
check_url "https://www.youtube.com/watch?v=abc12345" 0
check_url "https://youtu.be/abc12345"                0
check_url "https://vimeo.com/12345"                  0
check_url "https://youtube.com/"                      1
check_url "https://www.youtube.com/feed/subscriptions" 1
check_url "notaurl"                                   1

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
