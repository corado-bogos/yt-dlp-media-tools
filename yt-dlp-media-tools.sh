#!/usr/bin/env bash

set -o pipefail

clear

# =========================
# TERMINAL UI
# =========================
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
  BOLD=""
  DIM=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  RESET=""
fi

BAR_WIDTH=34
BOX_INNER_WIDTH=60
ACCENT="$MAGENTA"
DEFAULT_DOWNLOAD_PATH="$HOME/Desktop"

DOWNLOAD_STATUS=1
DOWNLOAD_HAS_ERRORS=0
COOKIE_ERROR_DETECTED=0

trap 'printf "\n"; warn "Download cancelled."; exit 130' INT

repeat_char() {
  local char="$1"
  local count="$2"
  local output=""
  local i

  for ((i = 0; i < count; i++)); do
    output+="$char"
  done

  printf "%s" "$output"
}

print_box() {
  local text="$1"
  local text_len="${#text}"
  local left_pad=$(( (BOX_INNER_WIDTH - text_len) / 2 ))
  local right_pad=$(( BOX_INNER_WIDTH - text_len - left_pad ))
  local rule

  if (( left_pad < 0 )); then
    left_pad=1
  fi

  if (( right_pad < 0 )); then
    right_pad=1
  fi

  rule="$(repeat_char "-" "$BOX_INNER_WIDTH")"

  printf "%s+%s+%s\n" "$ACCENT" "$rule" "$RESET"
  printf "%s|%s%*s%s%s%s%*s%s|%s\n" "$ACCENT" "$RESET" "$left_pad" "" "$BOLD" "$text" "$RESET" "$right_pad" "" "$ACCENT" "$RESET"
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

ok() {
  printf "%s[OK]%s %s\n" "$GREEN" "$RESET" "$1"
}

warn() {
  printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$1"
}

fail() {
  printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$1"
  exit 1
}

normalize_input() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

is_back() {
  local value
  value="$(normalize_input "$1")"
  [[ "$value" == "b" || "$value" == "back" ]]
}

is_exit() {
  local value
  value="$(normalize_input "$1")"
  [[ "$value" == "e" || "$value" == "exit" || "$value" == "q" || "$value" == "quit" ]]
}

exit_program() {
  printf "\n"
  ok "Done. Program closed."
  exit 0
}

is_cookie_issue_text() {
  local text
  text="$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')"

  [[ "$text" == *cookie* ]] ||
    [[ "$text" == *"operation not permitted"* ]] ||
    [[ "$text" == *"permission denied"* ]] ||
    [[ "$text" == *"full disk access"* ]] ||
    [[ "$text" == *"database is locked"* ]]
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing command: $1. Run ./install.sh first."
  fi
}

clear_line() {
  printf "\r\033[K"
}

render_bar() {
  local percent="$1"
  local whole="${percent%.*}"
  local filled empty bar i

  if [[ ! "$whole" =~ ^[0-9]+$ ]]; then
    whole=0
  fi

  if (( whole > 100 )); then
    whole=100
  fi

  filled=$(( whole * BAR_WIDTH / 100 ))
  empty=$(( BAR_WIDTH - filled ))
  bar=""

  for ((i = 0; i < filled; i++)); do
    bar+="#"
  done

  for ((i = 0; i < empty; i++)); do
    bar+="-"
  done

  clear_line
  printf "%sDownloading%s [%s%s%s] %6s%%" "$ACCENT" "$RESET" "$YELLOW" "$bar" "$RESET" "$percent"
}

render_progress() {
  local line percent
  local printed_progress=0

  while IFS= read -r line; do
    line="${line//$'\r'/}"

    if [[ "$line" =~ ERROR: ]]; then
      if is_cookie_issue_text "$line"; then
        clear_line
        warn "Browser cookies could not be loaded."
        continue
      fi

      DOWNLOAD_HAS_ERRORS=1
      clear_line
      printf "%s%s%s\n" "$RED" "$line" "$RESET"
      continue
    fi

    if [[ "$line" =~ WARNING: ]]; then
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

    case "$line" in
      *"[download] Downloading item "*|*"[download] Destination:"*|*"[download] Finished downloading playlist:"*)
        clear_line
        printf "%s%s%s\n" "$DIM" "$line" "$RESET"
        ;;
      *"Deleting original file "*|*"[Metadata]"*|*"[ExtractAudio]"*|*"[Merger]"*)
        clear_line
        printf "%s%s%s\n" "$DIM" "$line" "$RESET"
        ;;
      "")
        ;;
      *)
        clear_line
        printf "%s\n" "$line"
        ;;
    esac
  done

  if (( printed_progress == 1 )); then
    printf "\n"
  fi
}

run_ytdlp() {
  local status
  local temp_output

  temp_output="$(mktemp "${TMPDIR:-/tmp}/yt-dlp-media-tools.XXXXXX")" || fail "Could not create temporary output file."

  yt-dlp "$@" 2>&1 | tee "$temp_output" | render_progress
  status="${PIPESTATUS[0]}"

  if grep -q "ERROR:" "$temp_output" 2>/dev/null; then
    DOWNLOAD_HAS_ERRORS=1
  fi

  if grep -Eiq "ERROR:.*cookie|cookies?.*(not found|could not|failed|permission|denied)|operation not permitted|database is locked|full disk access" "$temp_output" 2>/dev/null; then
    COOKIE_ERROR_DETECTED=1
  fi

  command rm -f "$temp_output"

  return "$status"
}

prompt_save_location() {
  local input

  while true; do
    section "1/4" "Choose save location"
    printf "Default folder: %s\n\n" "$DEFAULT_DOWNLOAD_PATH"
    printf "Type %sexit%s to close the program.\n\n" "$BOLD" "$RESET"
    printf "%sExamples:%s\n" "$DIM" "$RESET"
    printf "  ~/Desktop\n"
    printf "  ~/Downloads\n"
    printf "  /Users/yourname/Music\n\n"

    read -r -p "Save location [press ENTER for Desktop]: " input

    if is_exit "$input"; then
      exit_program
    fi

    MUSIC_PATH="${input:-$DEFAULT_DOWNLOAD_PATH}"
    MUSIC_PATH="${MUSIC_PATH/#\~/$HOME}"

    if [[ -d "$MUSIC_PATH" ]]; then
      ok "Files will be saved to: $MUSIC_PATH"
      return 0
    fi

    warn "Folder does not exist: $MUSIC_PATH"
    warn "Please enter an existing folder."
    printf "\n"
  done
}

prompt_url() {
  local input

  while true; do
    section "2/4" "Paste playlist or video URL"
    printf "Type %sback%s to return to the previous step, or %sexit%s to close.\n\n" "$BOLD" "$RESET" "$BOLD" "$RESET"

    read -r -p "URL: " input

    if is_exit "$input"; then
      exit_program
    fi

    if is_back "$input"; then
      return 1
    fi

    if [[ -z "$input" ]]; then
      warn "URL cannot be empty. Please try again."
      printf "\n"
      continue
    fi

    if [[ ! "$input" =~ ^https?:// ]]; then
      warn "Invalid URL. It must start with http:// or https://"
      printf "\n"
      continue
    fi

    URL="$input"
    ok "URL accepted"
    return 0
  done
}

prompt_download_mode() {
  local input

  while true; do
    section "3/4" "Choose download mode"
    printf "Type %sback%s to return to the previous step, or %sexit%s to close.\n\n" "$BOLD" "$RESET" "$BOLD" "$RESET"
    printf "  %s1%s) MP4   - Best video quality\n" "$ACCENT" "$RESET"
    printf "  %s2%s) WEBM  - Native YouTube quality, thumbnail saved separately\n" "$ACCENT" "$RESET"
    printf "  %s3%s) MP3   - Maximum compatibility\n" "$ACCENT" "$RESET"
    printf "  %s4%s) M4A   - Good audio quality\n" "$ACCENT" "$RESET"
    printf "  %s5%s) FLAC  - No thumbnail image; does not improve source quality\n\n" "$ACCENT" "$RESET"
    printf "%sFLAC note:%s FLAC is lossless, but it cannot make YouTube/audio-stream quality better than the original source.\n\n" "$YELLOW" "$RESET"

    read -r -p "Select option (1-5): " input

    if is_exit "$input"; then
      exit_program
    fi

    if is_back "$input"; then
      return 1
    fi

    if [[ ! "$input" =~ ^[1-5]$ ]]; then
      warn "Invalid option. Choose a number between 1 and 5."
      printf "\n"
      continue
    fi

    CHOICE="$input"

    case "$CHOICE" in
      1) MODE_NAME="MP4 video" ;;
      2) MODE_NAME="WEBM video" ;;
      3) MODE_NAME="MP3 audio" ;;
      4) MODE_NAME="M4A audio" ;;
      5) MODE_NAME="FLAC audio" ;;
    esac

    ok "Selected mode: $MODE_NAME"

    if [[ "$CHOICE" == "2" ]]; then
      warn "WEBM mode saves the thumbnail separately as a JPG."
      warn "WEBM mode uses only WEBM video/audio streams to avoid broken video merges."
    fi

    if [[ "$CHOICE" == "5" ]]; then
      warn "FLAC mode does not save or embed thumbnail images."
    fi

    return 0
  done
}

prompt_yes_no() {
  local question="$1"
  local input

  while true; do
    read -r -p "$question (y/n): " input

    if is_exit "$input"; then
      exit_program
    fi

    input="$(normalize_input "$input")"

    case "$input" in
      y|yes)
        return 0
        ;;
      n|no|"")
        return 1
        ;;
      *)
        warn "Please type y or n."
        ;;
    esac
  done
}

verify_browser_cookies() {
  local browser="$1"
  local temp_output
  local status

  temp_output="$(mktemp "${TMPDIR:-/tmp}/yt-dlp-media-tools-cookie-check.XXXXXX")" || fail "Could not create temporary cookie check file."

  yt-dlp --cookies-from-browser "$browser" --simulate --skip-download --no-playlist --no-warnings "$URL" >"$temp_output" 2>&1
  status=$?

  if grep -Eiq "ERROR:.*cookie|cookies?.*(not found|could not|failed|permission|denied)|operation not permitted|database is locked|full disk access|extracted 0 cookies" "$temp_output" 2>/dev/null; then
    command rm -f "$temp_output"
    return 1
  fi

  command rm -f "$temp_output"

  if [[ "$status" -ne 0 ]]; then
    return 0
  fi

  return 0
}

prompt_cookies() {
  local input

  while true; do
    section "4/4" "Browser cookies"
    printf "Cookies are optional. They help with restricted videos, private videos, large playlists, and rate limits.\n\n"
    printf "Type %sback%s to return to the previous step, or %sexit%s to close.\n\n" "$BOLD" "$RESET" "$BOLD" "$RESET"
    printf "  %s0%s) Skip cookies\n" "$ACCENT" "$RESET"
    printf "  %s1%s) Chrome\n" "$ACCENT" "$RESET"
    printf "  %s2%s) Firefox\n" "$ACCENT" "$RESET"
    printf "  %s3%s) Safari\n" "$ACCENT" "$RESET"
    printf "  %s4%s) Edge\n" "$ACCENT" "$RESET"
    printf "  %s5%s) Brave\n\n" "$ACCENT" "$RESET"

    read -r -p "Select option (0-5): " input

    if is_exit "$input"; then
      exit_program
    fi

    if is_back "$input"; then
      return 1
    fi

    if [[ ! "$input" =~ ^[0-5]$ ]]; then
      warn "Invalid option. Choose a number between 0 and 5."
      printf "\n"
      continue
    fi

    COOKIE_ARGS=()

    case "$input" in
      0)
        warn "No cookies selected. Some content may be unavailable."
        return 0
        ;;
      1) BROWSER="chrome" ;;
      2) BROWSER="firefox" ;;
      3) BROWSER="safari" ;;
      4) BROWSER="edge" ;;
      5) BROWSER="brave" ;;
    esac

    if [[ "$BROWSER" == "safari" ]]; then
      printf "\n"
      warn "Safari cookies may be blocked by macOS permissions."
      printf "If Safari fails, use Chrome, Brave, Edge, or Firefox instead.\n"
      printf "For Safari cookies, Terminal may need Full Disk Access.\n\n"
    fi

    COOKIE_ARGS=(--cookies-from-browser "$BROWSER")

    if ! verify_browser_cookies "$BROWSER"; then
      warn "No usable cookies were found for: $BROWSER"

      if prompt_yes_no "Download anyway without cookies?"; then
        COOKIE_ARGS=()
        warn "Continuing without cookies."
        return 0
      fi

      printf "\n"
      continue
    fi

    ok "Cookies will be loaded from: $BROWSER"
    return 0
  done
}

build_ytdlp_args() {
  OUTPUT_TEMPLATE="%(playlist_index)03d - %(uploader)s - %(title)s.%(ext)s"

  COMMON_ARGS=(
    --yes-playlist
    "${COOKIE_ARGS[@]}"
    --download-archive "archive.txt"
    --ignore-errors
    --retries 20
    --fragment-retries 20
    --concurrent-fragments 1
    --windows-filenames
    --newline
    --no-color
    --no-keep-video
    -o "$OUTPUT_TEMPLATE"
  )

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
        --embed-thumbnail
        --add-metadata
      )
      ;;
    4)
      MODE_ARGS=(
        -f bestaudio
        -x
        --audio-format m4a
        --embed-thumbnail
        --add-metadata
      )
      ;;
    5)
      MODE_ARGS=(
        -f bestaudio
        -x
        --audio-format flac
        --add-metadata
      )
      ;;
  esac
}

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
          step=1
        fi
        ;;
      3)
        if prompt_download_mode; then
          step=4
        else
          step=2
        fi
        ;;
      4)
        if prompt_cookies; then
          break
        else
          step=3
        fi
        ;;
    esac
  done

  if ! cd "$MUSIC_PATH"; then
    fail "Could not open folder: $MUSIC_PATH"
  fi

  build_ytdlp_args

  section "RUN" "Starting download"
  printf "Save folder : %s\n" "$MUSIC_PATH"
  printf "Mode        : %s\n\n" "$MODE_NAME"

  while true; do
    COOKIE_ERROR_DETECTED=0
    DOWNLOAD_HAS_ERRORS=0

    run_ytdlp "${COMMON_ARGS[@]}" "${MODE_ARGS[@]}" "$URL"
    DOWNLOAD_STATUS=$?

    if [[ "$COOKIE_ERROR_DETECTED" -eq 1 && "${#COOKIE_ARGS[@]}" -gt 0 ]]; then
      printf "\n"
      warn "Browser cookies could not be loaded from: $BROWSER"

      if prompt_yes_no "Download anyway without cookies?"; then
        COOKIE_ARGS=()
        build_ytdlp_args
        printf "\n"
        warn "Retrying without cookies."
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
    warn "Try another browser cookie option, update yt-dlp, or check TROUBLESHOOTING.md."
  fi
}

prompt_continue() {
  local input

  while true; do
    printf "\n"
    read -r -p "Do you want to continue downloading? (y/n, or exit): " input

    if is_exit "$input"; then
      exit_program
    fi

    input="$(normalize_input "$input")"

    case "$input" in
      y|yes)
        return 0
        ;;
      n|no|"")
        return 1
        ;;
      *)
        warn "Please type y/n, or exit."
        ;;
    esac
  done
}

print_header

require_command "yt-dlp"

if ! command -v ffmpeg >/dev/null 2>&1; then
  warn "ffmpeg was not found. MP4 merge, audio conversion, and thumbnails may fail."
fi

while true; do
  download_once

  if prompt_continue; then
    print_header
    continue
  fi

  printf "\n"
  ok "Done. Program closed."
  break
done
