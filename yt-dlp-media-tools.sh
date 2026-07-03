#!/usr/bin/env bash

set -uo pipefail

VERSION="1.2.2"

# ── CLI flags ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf "ytmt — interactive media downloader\n\n"
  printf "Usage:\n"
  printf "  ytmt             Start the download wizard\n"
  printf "  ytmt --help      Show this help\n"
  printf "  ytmt --version   Show version\n\n"
  printf "Formats: MP4, WEBM, MP3, M4A, FLAC\n\n"
  printf "Environment:\n"
  printf "  YTMT_KEEP_LOG=1  Save full yt-dlp log to the download folder\n\n"
  printf "Version : %s\n" "$VERSION"
  printf "Website : https://github.com/corado-bogos/yt-dlp-media-tools\n"
  exit 0
fi

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  printf "yt-dlp-media-tools v%s\n" "$VERSION"
  exit 0
fi

# ── PATH: Homebrew + ~/.local/bin ─────────────────────────────────────────────
for _ytmt_brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$_ytmt_brew" ]]; then
    eval "$("$_ytmt_brew" shellenv)"
    break
  fi
done
unset _ytmt_brew

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ── Temp file cleanup ─────────────────────────────────────────────────────────
_YTMT_TEMP_FILES=()
_YTMT_LAST_TEMP_FILE=""

cleanup_temp_files() {
  local file
  for file in ${_YTMT_TEMP_FILES[@]+"${_YTMT_TEMP_FILES[@]}"}; do
    if [[ -f "$file" ]]; then command rm -f "$file" 2>/dev/null; fi
  done
  _YTMT_TEMP_FILES=()
}

trap cleanup_temp_files EXIT

clear

# ── Terminal colors ───────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold)"
  DIM="$(tput dim)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  MAGENTA="$(tput setaf 5)"
  RESET="$(tput sgr0)"
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" RESET=""
fi

BAR_WIDTH=34
BOX_INNER_WIDTH=60
ACCENT="$MAGENTA"
DEFAULT_DOWNLOAD_PATH="$HOME/Desktop"

DOWNLOAD_STATUS=1
DOWNLOAD_HAS_ERRORS=0
COOKIE_ERROR_DETECTED=0
FFMPEG_AVAILABLE=0
FFMPEG_WARNING_SHOWN=0
ARCHIVE_ENABLED=1
LAST_LOG_PATH=""

# ── UI primitives ─────────────────────────────────────────────────────────────
repeat_char() {
  local char="$1" count="$2" output="" i
  for ((i = 0; i < count; i++)); do output+="$char"; done
  printf "%s" "$output"
}

print_box() {
  local text="$1"
  local text_len="${#text}"
  local left_pad=$(( (BOX_INNER_WIDTH - text_len) / 2 ))
  local right_pad=$(( BOX_INNER_WIDTH - text_len - left_pad ))
  local rule

  (( left_pad  < 1 )) && left_pad=1
  (( right_pad < 1 )) && right_pad=1

  rule="$(repeat_char "-" "$BOX_INNER_WIDTH")"

  printf "%s+%s+%s\n" "$ACCENT" "$rule" "$RESET"
  printf "%s|%s%*s%s%s%s%*s%s|%s\n" \
    "$ACCENT" "$RESET" "$left_pad" "" "$BOLD" "$text" "$RESET" "$right_pad" "" "$ACCENT" "$RESET"
  printf "%s+%s+%s\n" "$ACCENT" "$rule" "$RESET"
}

print_header() {
  clear
  print_box "MEDIA DOWNLOADER  |  yt-dlp tool"
  printf "\n"
}

section() {
  printf "\n%s[%s]%s %s%s%s\n" "$ACCENT" "$1" "$RESET" "$BOLD" "$2" "$RESET"
  printf "%s------------------------------------------------------------%s\n" "$DIM" "$RESET"
}

ok()   { printf "%s[OK]%s %s\n"    "$GREEN"  "$RESET" "$1"; }
warn() { printf "%s[WARN]%s %s\n"  "$YELLOW" "$RESET" "$1"; }
fail() { printf "%s[ERROR]%s %s\n" "$RED"    "$RESET" "$1"; exit 1; }

# INT trap registered after warn() is defined
trap 'printf "\n"; warn "Download cancelled."; exit 130' INT

nav_hint() {
  printf "%sback%s • %sexit%s\n\n" "$DIM" "$RESET" "$DIM" "$RESET"
}

normalize_input() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

trim_input() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf "%s" "$s"
}

is_back() {
  local v
  v="$(normalize_input "$1")"
  [[ "$v" == "b" || "$v" == "back" ]]
}

is_exit() {
  local v
  v="$(normalize_input "$1")"
  [[ "$v" == "e" || "$v" == "exit" || "$v" == "q" || "$v" == "quit" ]]
}

exit_program() {
  printf "\n"
  ok "Done. Program closed."
  exit 0
}

is_cookie_issue_text() {
  local text
  text="$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$text" == *cookie*                    ]] ||
  [[ "$text" == *"operation not permitted"* ]] ||
  [[ "$text" == *"permission denied"*       ]] ||
  [[ "$text" == *"full disk access"*        ]] ||
  [[ "$text" == *"database is locked"*      ]]
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing: $1. Open a new terminal and try again, or run ./install.sh."
  fi
}

# ── URL validation ────────────────────────────────────────────────────────────
# Rejects bare domains, homepages, and known non-downloadable YouTube pages.
# Only URLs with a real content path or query are accepted.
is_valid_url() {
  local url="$1"

  # Must be HTTP(S)
  [[ "$url" =~ ^https?:// ]] || return 1

  # Extract host (everything between :// and first /, ?, or end)
  local rest="${url#*://}"
  local host="${rest%%/*}"
  local after_host="${rest#"$host"}"

  # Strip optional port
  host="${host%%:*}"

  # Host must be a real dotted domain
  [[ "$host" == *.* ]] || return 1

  # Must have more than just a bare domain or trailing slash
  case "$after_host" in
    ""|"/") return 1 ;;
  esac

  # Reject known YouTube non-content pages
  local lh lp
  lh="$(printf "%s" "$host"        | tr '[:upper:]' '[:lower:]')"
  lp="$(printf "%s" "$after_host"  | tr '[:upper:]' '[:lower:]')"

  case "$lh" in
    youtube.com|www.youtube.com|m.youtube.com)
      case "$lp" in
        /|/feed|/feed/*|/feed\?*|/results|/results/*|/results\?*|/gaming|/trending|/explore)
          return 1 ;;
      esac
      ;;
    youtu.be|www.youtu.be)
      # Must have a video ID path segment
      [[ "$lp" =~ ^/[a-z0-9_-]{2,} ]] || return 1
      ;;
  esac

  return 0
}

# ── yt-dlp update command detection ──────────────────────────────────────────
# Inspects the yt-dlp binary path to determine how it was installed,
# then returns the correct update command for that install method.
ytdlp_update_command() {
  local path
  path="$(command -v yt-dlp 2>/dev/null)" || { printf "yt-dlp -U"; return; }
  case "$path" in
    /opt/homebrew/*|/usr/local/Cellar/*|/home/linuxbrew/*)
      printf "brew upgrade yt-dlp" ;;
    */pipx/*)
      printf "pipx upgrade yt-dlp" ;;
    */site-packages/*|*/dist-packages/*)
      printf "pip3 install -U yt-dlp" ;;
    *)
      printf "yt-dlp -U" ;;
  esac
}

# ── Progress bar ──────────────────────────────────────────────────────────────
clear_line() { printf "\r\033[K"; }

render_bar() {
  local percent="$1"
  local whole="${percent%.*}"
  local filled empty bar i

  [[ "$whole" =~ ^[0-9]+$ ]] || whole=0
  (( whole > 100 )) && whole=100

  filled=$(( whole * BAR_WIDTH / 100 ))
  empty=$(( BAR_WIDTH - filled ))
  bar=""

  for ((i = 0; i < filled; i++)); do bar+="#"; done
  for ((i = 0; i < empty;  i++)); do bar+="-"; done

  clear_line
  printf "%sDownloading%s [%s%s%s] %6s%%" "$ACCENT" "$RESET" "$YELLOW" "$bar" "$RESET" "$percent"
}

# Filters yt-dlp's output: shows the progress bar, warnings, and errors.
# All bracket-prefixed internal status lines are suppressed.
render_progress() {
  local line percent
  local printed_progress=0

  while IFS= read -r line; do
    line="${line//$'\r'/}"

    if [[ "$line" =~ ^ERROR: ]]; then
      if is_cookie_issue_text "$line"; then
        clear_line
        warn "Browser cookies could not be loaded."
        continue
      fi
      clear_line
      printf "%s%s%s\n" "$RED" "$line" "$RESET"
      continue
    fi

    if [[ "$line" =~ ^WARNING: ]]; then
      clear_line
      printf "%s%s%s\n" "$YELLOW" "$line" "$RESET"
      continue
    fi

    if [[ "$line" =~ ([0-9]+([.][0-9]+)?)% ]]; then
      percent="${BASH_REMATCH[1]}"
      render_bar "$percent"
      printed_progress=1
      continue
    fi

    # Suppress everything else — bracket lines, cookie messages,
    # "Deleting original file", "Extracted N cookies", etc.
  done

  (( printed_progress == 1 )) && printf "\n"
}

# ── yt-dlp runner ─────────────────────────────────────────────────────────────
# Creates a tracked temp file and stores its path in _YTMT_LAST_TEMP_FILE.
# It must NOT be called via command substitution: the _YTMT_TEMP_FILES+=()
# append (and any fail() exit) would run in a subshell and be discarded,
# defeating the EXIT-trap cleanup. Callers read _YTMT_LAST_TEMP_FILE instead.
create_temp_file() {
  local f
  f="$(mktemp "${TMPDIR:-/tmp}/yt-dlp-media-tools.XXXXXX")" || fail "Could not create temporary file."
  chmod 600 "$f"
  _YTMT_TEMP_FILES+=("$f")
  _YTMT_LAST_TEMP_FILE="$f"
}

run_ytdlp() {
  local status
  local temp_output
  create_temp_file
  temp_output="$_YTMT_LAST_TEMP_FILE"

  yt-dlp "$@" 2>&1 | tee "$temp_output" | render_progress
  status="${PIPESTATUS[0]}"

  DOWNLOAD_HAS_ERRORS=0
  COOKIE_ERROR_DETECTED=0

  # Error state is read from the temp file, not from render_progress.
  # render_progress runs in a subshell (last stage of a pipe), so any
  # variable assignments inside it are discarded when the subshell exits.
  # The cookie grep is anchored to ^ERROR: lines to prevent WARNING lines
  # that mention "cookie" from triggering a false COOKIE_ERROR_DETECTED.
  if grep -Eiq "^ERROR:.*(cookie|operation not permitted|permission denied|full disk access|database is locked)" \
      "$temp_output" 2>/dev/null; then
    COOKIE_ERROR_DETECTED=1
  elif grep -q "^ERROR:" "$temp_output" 2>/dev/null; then
    DOWNLOAD_HAS_ERRORS=1
  fi

  if [[ "${YTMT_KEEP_LOG:-0}" == "1" ]]; then
    LAST_LOG_PATH="$MUSIC_PATH/ytmt-last-run.log"
    cp "$temp_output" "$LAST_LOG_PATH"
  fi

  return "$status"
}

# ── Cookie check ──────────────────────────────────────────────────────────────
check_browser_cookie_access() {
  local browser="$1"
  local temp_output status

  create_temp_file
  temp_output="$_YTMT_LAST_TEMP_FILE"

  printf "Checking cookies from %s..." "$browser"
  yt-dlp --cookies-from-browser "$browser" --simulate --skip-download \
    --no-playlist --no-warnings "$URL" >"$temp_output" 2>&1
  status=$?
  clear_line

  if grep -Eiq \
    "ERROR:.*cookie|cookies?.*(not found|could not|failed|permission|denied)|operation not permitted|database is locked|full disk access|extracted 0 cookies" \
    "$temp_output" 2>/dev/null; then
    return 1
  fi

  [[ "$status" -ne 0 ]] && return 2

  return 0
}

# ── ffmpeg guard ──────────────────────────────────────────────────────────────
ensure_ffmpeg_available() {
  [[ "$FFMPEG_AVAILABLE" -eq 1 ]] && return 0

  if [[ "$FFMPEG_WARNING_SHOWN" -eq 0 ]]; then
    warn "This mode requires ffmpeg, which was not found."
    warn "Run ./install.sh to install ffmpeg, then try again."
    FFMPEG_WARNING_SHOWN=1
  fi

  return 1
}

# ── Prompt: save location (step 1) ───────────────────────────────────────────
prompt_save_location() {
  local input

  while true; do
    section "1/4" "Save location"
    printf "Default: %s\n\n" "$DEFAULT_DOWNLOAD_PATH"
    printf "%sexit%s\n\n" "$DIM" "$RESET"

    read -r -p "Path [Enter for Desktop]: " input

    if is_exit "$input"; then
      exit_program
    fi

    MUSIC_PATH="${input:-$DEFAULT_DOWNLOAD_PATH}"
    MUSIC_PATH="${MUSIC_PATH/#\~/$HOME}"

    if [[ -d "$MUSIC_PATH" ]] && [[ -w "$MUSIC_PATH" ]]; then
      ok "Saving to: $MUSIC_PATH"
      printf "\n"
      local archive_input
      read -r -p "Skip already-downloaded files? (Y/n): " archive_input
      if is_exit "$archive_input"; then exit_program; fi
      if is_back "$archive_input"; then printf "\n"; continue; fi
      case "$(normalize_input "$archive_input")" in
        n|no) ARCHIVE_ENABLED=0 ;;
        *)    ARCHIVE_ENABLED=1 ;;
      esac
      return 0
    fi

    warn "Folder not found or not writable: $MUSIC_PATH"
    printf "\n"
  done
}

# ── Prompt: URL (step 2) ──────────────────────────────────────────────────────
prompt_url() {
  local input

  while true; do
    section "2/4" "Video or playlist URL"
    nav_hint

    read -r -p "URL: " input

    if is_exit "$input"; then exit_program; fi
    if is_back "$input"; then return 1; fi

    input="$(trim_input "$input")"

    if [[ -z "$input" ]]; then
      warn "URL cannot be empty."
      printf "\n"
      continue
    fi

    if ! is_valid_url "$input"; then
      warn "Invalid URL. Paste the full link to a video or playlist."
      printf "\n"
      continue
    fi

    URL="$input"
    ok "URL accepted"
    return 0
  done
}

# ── Prompt: download mode (step 3) ───────────────────────────────────────────
prompt_download_mode() {
  local input

  while true; do
    section "3/4" "Download mode"
    nav_hint
    printf "  %s1%s) MP4   Best video quality\n"                          "$ACCENT" "$RESET"
    printf "  %s2%s) WEBM  Native YouTube quality, thumbnail saved as JPG\n" "$ACCENT" "$RESET"
    printf "  %s3%s) MP3   Maximum compatibility\n"                       "$ACCENT" "$RESET"
    printf "  %s4%s) M4A   Good audio quality\n"                          "$ACCENT" "$RESET"
    printf "  %s5%s) FLAC  Lossless (no thumbnail)\n\n"                   "$ACCENT" "$RESET"

    read -r -p "Select (1-5): " input

    if is_exit "$input"; then exit_program; fi
    if is_back "$input"; then return 1; fi

    if [[ ! "$input" =~ ^[1-5]$ ]]; then
      warn "Choose a number between 1 and 5."
      printf "\n"
      continue
    fi

    CHOICE="$input"

    case "$CHOICE" in
      1) MODE_NAME="MP4 video"  ;;
      2) MODE_NAME="WEBM video" ;;
      3) MODE_NAME="MP3 audio"  ;;
      4) MODE_NAME="M4A audio"  ;;
      5) MODE_NAME="FLAC audio" ;;
    esac

    ok "Mode: $MODE_NAME"

    [[ "$CHOICE" == "2" ]] && warn "WEBM: thumbnail saved separately as JPG."
    [[ "$CHOICE" == "5" ]] && warn "FLAC: no thumbnail. Source quality cannot be improved."

    if ! ensure_ffmpeg_available; then
      printf "\n"
      continue
    fi

    return 0
  done
}

# ── Prompt: y/n ───────────────────────────────────────────────────────────────
prompt_yes_no() {
  local question="$1"
  local input

  while true; do
    read -r -p "$question (y/n): " input

    if is_exit "$input"; then exit_program; fi

    case "$(normalize_input "$input")" in
      y|yes)   return 0 ;;
      n|no|"") return 1 ;;
      *)        warn "Type y or n." ;;
    esac
  done
}

# ── Prompt: browser cookies (step 4) ─────────────────────────────────────────
prompt_cookies() {
  local input

  while true; do
    section "4/4" "Browser cookies"
    printf "Optional. Helps with restricted videos, large playlists, and rate limits.\n\n"
    nav_hint
    printf "  %s0%s) Skip\n"    "$ACCENT" "$RESET"
    printf "  %s1%s) Chrome\n"  "$ACCENT" "$RESET"
    printf "  %s2%s) Firefox\n" "$ACCENT" "$RESET"
    printf "  %s3%s) Safari\n"  "$ACCENT" "$RESET"
    printf "  %s4%s) Edge\n"    "$ACCENT" "$RESET"
    printf "  %s5%s) Brave\n\n" "$ACCENT" "$RESET"

    read -r -p "Select (0-5): " input

    if is_exit "$input"; then exit_program; fi
    if is_back "$input"; then return 1; fi

    if [[ ! "$input" =~ ^[0-5]$ ]]; then
      warn "Choose a number between 0 and 5."
      printf "\n"
      continue
    fi

    COOKIE_ARGS=()
    BROWSER=""

    case "$input" in
      0) return 0 ;;
      1) BROWSER="chrome"  ;;
      2) BROWSER="firefox" ;;
      3) BROWSER="safari"  ;;
      4) BROWSER="edge"    ;;
      5) BROWSER="brave"   ;;
    esac

    COOKIE_ARGS=(--cookies-from-browser "$BROWSER")

    check_browser_cookie_access "$BROWSER"
    case "$?" in
      0)
        ok "Cookies loaded from: $BROWSER"
        ;;
      1)
        warn "No usable cookies found for: $BROWSER"
        if [[ "$BROWSER" == "safari" ]]; then
          printf "Safari needs Full Disk Access for Terminal.\n"
          printf "System Settings → Privacy & Security → Full Disk Access\n\n"
        fi
        if prompt_yes_no "Continue without cookies?"; then
          COOKIE_ARGS=()
          BROWSER=""
          return 0
        fi
        printf "\n"
        continue
        ;;
      2)
        warn "Cookie check inconclusive — will attempt download with $BROWSER."
        ;;
    esac

    return 0
  done
}

# ── Build yt-dlp argument arrays ─────────────────────────────────────────────
build_ytdlp_args() {
  # Prefix the output template with MUSIC_PATH so files always land in the
  # user-selected folder regardless of the script's working directory.
  local template
  template="$MUSIC_PATH/%(playlist_index&{:03d} - |)s%(artist,uploader,creator,channel|Unknown Artist)s - %(title|Untitled)s.%(ext)s"

  COMMON_ARGS=(
    --yes-playlist
    ${COOKIE_ARGS[@]+"${COOKIE_ARGS[@]}"}
    --ignore-errors
    --retries 20
    --fragment-retries 20
    --concurrent-fragments 1
    --windows-filenames
    --newline
    --no-color
    -o "$template"
  )

  if [[ "$ARCHIVE_ENABLED" -eq 1 ]]; then
    COMMON_ARGS+=(--download-archive "$MUSIC_PATH/archive.txt")
  fi

  case "$CHOICE" in
    1)
      MODE_ARGS=(
        -f "bv*+ba/b"
        --merge-output-format mp4
        --embed-thumbnail
        --add-metadata
      )
      ;;
    2)
      MODE_ARGS=(
        -f "bv*[ext=webm]+ba[ext=webm]/b[ext=webm]"
        --merge-output-format webm
        --write-thumbnail
        --convert-thumbnails jpg
        --add-metadata
      )
      ;;
    3)
      MODE_ARGS=(
        -f bestaudio
        -x
        --audio-format mp3
        --audio-quality 0
        --no-keep-video
        --embed-thumbnail
        --add-metadata
      )
      ;;
    4)
      MODE_ARGS=(
        -f bestaudio
        -x
        --audio-format m4a
        --no-keep-video
        --embed-thumbnail
        --add-metadata
      )
      ;;
    5)
      MODE_ARGS=(
        -f bestaudio
        -x
        --audio-format flac
        --no-keep-video
        --add-metadata
      )
      ;;
  esac
}

# ── One download session ──────────────────────────────────────────────────────
download_once() {
  local step=1

  DOWNLOAD_STATUS=1
  DOWNLOAD_HAS_ERRORS=0
  MUSIC_PATH=""
  URL=""
  CHOICE=""
  MODE_NAME=""
  BROWSER=""
  COOKIE_ARGS=()

  while true; do
    case "$step" in
      1)
        prompt_save_location
        step=2
        ;;
      2)
        if prompt_url; then
          step=3
        else
          print_header
          step=1
        fi
        ;;
      3)
        if prompt_download_mode; then
          step=4
        else
          print_header
          step=2
        fi
        ;;
      4)
        if prompt_cookies; then
          break
        else
          print_header
          step=3
        fi
        ;;
    esac
  done

  if ! [[ -d "$MUSIC_PATH" ]] || ! [[ -w "$MUSIC_PATH" ]]; then
    fail "Save folder no longer exists or is not writable: $MUSIC_PATH"
  fi

  build_ytdlp_args

  section "RUN" "Starting download"
  printf "Folder : %s\n" "$MUSIC_PATH"
  printf "Format : %s\n\n" "$MODE_NAME"

  while true; do
    COOKIE_ERROR_DETECTED=0
    DOWNLOAD_HAS_ERRORS=0

    run_ytdlp "${COMMON_ARGS[@]}" "${MODE_ARGS[@]}" "$URL"
    DOWNLOAD_STATUS=$?

    if [[ "$COOKIE_ERROR_DETECTED" -eq 1 && "${#COOKIE_ARGS[@]}" -gt 0 ]]; then
      printf "\n"
      warn "Cookie error with: $BROWSER"
      if prompt_yes_no "Retry without cookies?"; then
        COOKIE_ARGS=()
        BROWSER=""
        build_ytdlp_args
        printf "\n"
        continue
      fi
    fi

    break
  done

  printf "\n"

  if [[ "$DOWNLOAD_STATUS" -eq 0 && "$DOWNLOAD_HAS_ERRORS" -eq 0 ]]; then
    print_box "DOWNLOAD COMPLETE"
    ok "Files saved to: $MUSIC_PATH"
  else
    print_box "DOWNLOAD FINISHED WITH ERRORS"
    warn "Some items may not have downloaded correctly."
    warn "To update yt-dlp: $(ytdlp_update_command)"
    warn "See TROUBLESHOOTING.md for help."
  fi

  if [[ -n "$LAST_LOG_PATH" ]]; then
    printf "%s[INFO]%s Log saved to: %s\n" "$BLUE" "$RESET" "$LAST_LOG_PATH"
  fi
}

# ── Continue prompt ───────────────────────────────────────────────────────────
prompt_continue() {
  local input

  printf "\n"
  read -r -p "Download again? (y/exit): " input

  if is_exit "$input"; then
    exit_program
  fi

  case "$(normalize_input "$input")" in
    n|no) exit_program ;;
  esac
  # Enter or y = continue
}

# ── Entry point ───────────────────────────────────────────────────────────────
print_header

require_command "yt-dlp"

if ! command -v ffmpeg >/dev/null 2>&1; then
  FFMPEG_AVAILABLE=0
  warn "ffmpeg not found. All download modes require ffmpeg."
  warn "Run ./install.sh to install it."
else
  FFMPEG_AVAILABLE=1
fi

while true; do
  download_once
  prompt_continue
  print_header
done
