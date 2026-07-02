#!/usr/bin/env bash

set -euo pipefail

VERSION="1.2.1-beta.3"
SCRIPT_NAME="yt-dlp-media-tools.sh"
REQUIRED_COMMANDS=(yt-dlp ffmpeg)

REPO_URL="${YTMT_REPO_URL:-https://github.com/corado-bogos/yt-dlp-media-tools.git}"
INSTALL_DIR="${YTMT_INSTALL_DIR:-$HOME/.local/share/yt-dlp-media-tools}"
BIN_DIR="${YTMT_BIN_DIR:-$HOME/.local/bin}"
COMMAND_NAME="ytmt"
STEP_NUMBER=0
HOMEBREW_READY=0
PROFILE_UPDATED=0
LOG_FILE="${YTMT_LOG_FILE:-$HOME/.cache/yt-dlp-media-tools/install.log}"

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  RESET="$(tput sgr0)"
else
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

info() {
  printf "  %s->%s %s\n" "$BLUE" "$RESET" "$1"
}

ok() {
  printf "  %s[OK]%s %s\n" "$GREEN" "$RESET" "$1"
}

warn() {
  printf "  %s[WARN]%s %s\n" "$YELLOW" "$RESET" "$1"
}

fail() {
  log "ERROR: $1"
  printf "  %s[ERROR]%s %s\n" "$RED" "$RESET" "$1"
  exit 1
}

log() {
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || return 0
  printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null || true
}

step() {
  STEP_NUMBER=$((STEP_NUMBER + 1))
  printf "\n%s==> Step %s: %s%s\n" "$BOLD$BLUE" "$STEP_NUMBER" "$1" "$RESET"
}

note() {
  printf "     %s\n" "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

command_runs() {
  "$@" >/dev/null 2>&1
}

prompt_yes_no() {
  local prompt="$1"
  local answer

  if [[ "${YTMT_ASSUME_YES:-0}" == "1" ]]; then
    info "$prompt yes (YTMT_ASSUME_YES=1)"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    fail "$prompt Re-run in an interactive terminal or set YTMT_ASSUME_YES=1."
  fi

  printf "  %s [y/N]: " "$prompt"
  if ! read -r answer; then
    fail "Cannot continue without confirmation."
  fi

  case "$answer" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

missing_commands() {
  local missing=()
  local command_name

  for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$command_name"; then
      missing+=("$command_name")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    printf "%s\n" "${missing[@]}"
  fi
}

# ----------------------------------------------------------------------------
# PATH persistence
# ----------------------------------------------------------------------------
PROFILE_BLOCK_START="# >>> yt-dlp-media-tools installer >>>"
PROFILE_BLOCK_END="# <<< yt-dlp-media-tools installer <<<"

shell_profile_files() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"

  case "$shell_name" in
    zsh)
      printf "%s\n" "$HOME/.zprofile" "$HOME/.zshrc"
      ;;
    bash)
      printf "%s\n" "$HOME/.bash_profile" "$HOME/.bashrc"
      ;;
    *)
      printf "%s\n" "$HOME/.profile"
      ;;
  esac
}

persist_line() {
  local line="$1"
  local file
  local temp_file
  local current_line
  local inserted

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    touch "$file" 2>/dev/null || continue

    if ! grep -qF "$line" "$file" 2>/dev/null; then
      if grep -qF "$PROFILE_BLOCK_END" "$file" 2>/dev/null; then
        temp_file="$(mktemp "${TMPDIR:-/tmp}/ytmt-profile.XXXXXX")" || continue
        inserted=0

        while IFS= read -r current_line || [[ -n "$current_line" ]]; do
          if [[ "$current_line" == "$PROFILE_BLOCK_END" && "$inserted" -eq 0 ]]; then
            printf "%s\n" "$line" >> "$temp_file"
            inserted=1
          fi
          printf "%s\n" "$current_line" >> "$temp_file"
        done < "$file"

        cat "$temp_file" > "$file"
        command rm -f "$temp_file"
      else
        printf '\n%s\n%s\n%s\n' "$PROFILE_BLOCK_START" "$line" "$PROFILE_BLOCK_END" >> "$file"
      fi

      PROFILE_UPDATED=1
    fi
  done < <(shell_profile_files)
}

find_homebrew() {
  local brew_path

  if command_exists brew; then
    command -v brew
    return 0
  fi

  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      printf "%s\n" "$brew_path"
      return 0
    fi
  done

  return 1
}

setup_homebrew_path() {
  local brew_path

  if ! brew_path="$(find_homebrew)"; then
    return 1
  fi

  eval "$("$brew_path" shellenv)"
  persist_line "eval \"\$($brew_path shellenv)\""
  info "Using Homebrew: $brew_path"
  return 0
}

has_macos_command_line_tools() {
  xcode-select -p >/dev/null 2>&1
}

print_command_line_tools_help() {
  warn "Apple Command Line Tools are required before installing developer tools."
  note "macOS uses them for compilers, headers, and Git support."
  note "Run this command, finish the Apple popup, then run this installer again:"
  printf "\n  xcode-select --install\n\n"
}

ensure_macos_command_line_tools() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return 0
  fi

  step "Checking Apple Command Line Tools"

  if has_macos_command_line_tools; then
    ok "Apple Command Line Tools are installed"
    return 0
  fi

  print_command_line_tools_help

  if prompt_yes_no "Open the Apple Command Line Tools installer now?"; then
    info "Opening Apple Command Line Tools installer..."
    if xcode-select --install >/dev/null 2>&1; then
      ok "Apple installer opened"
    else
      warn "macOS could not open the installer, or it is already open."
    fi

    if [[ -t 0 ]]; then
      printf "  Finish the Apple installation window, then press Enter here to continue..."
      read -r _ || true
      if has_macos_command_line_tools; then
        ok "Apple Command Line Tools are now installed"
        return 0
      fi
    fi
  fi

  fail "Install Apple Command Line Tools with 'xcode-select --install', then run this installer again."
}

install_homebrew() {
  if ! command_exists curl; then
    fail "curl is required to install Homebrew. Install curl first, then run this installer again."
  fi

  info "Running the official Homebrew installer..."
  if [[ "${YTMT_ASSUME_YES:-0}" == "1" ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if ! setup_homebrew_path; then
    warn "Homebrew installed, but it is not available in this terminal yet."
    note "Apple Silicon:"
    printf "  eval \"\$(/opt/homebrew/bin/brew shellenv)\"\n"
    note "Intel Mac:"
    printf "  eval \"\$(/usr/local/bin/brew shellenv)\"\n"
    fail "Run the correct Homebrew PATH command above, then run this installer again."
  fi
}

ensure_homebrew() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return 0
  fi

  if [[ "$HOMEBREW_READY" -eq 1 ]]; then
    return 0
  fi

  step "Checking Homebrew"

  if setup_homebrew_path; then
    ok "Homebrew is ready"
    HOMEBREW_READY=1
    return 0
  fi

  warn "Homebrew was not found."
  note "Homebrew is needed on macOS to install git, yt-dlp, and ffmpeg."

  if prompt_yes_no "Install Homebrew now?"; then
    install_homebrew
    ok "Homebrew is ready"
    HOMEBREW_READY=1
  else
    fail "Install Homebrew from https://brew.sh, then run this installer again."
  fi
}

install_with_homebrew() {
  local packages=("$@")
  local brew_path

  ensure_homebrew

  brew_path="$(command -v brew)"
  info "Installing missing packages with Homebrew: ${packages[*]}"
  "$brew_path" install "${packages[@]}"
}

install_packages() {
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    return 0
  fi

  install_with_homebrew "${packages[@]}"
}

confirm_install_packages() {
  local packages
  packages="$*"

  if ! prompt_yes_no "Install missing packages now? ($packages)"; then
    fail "Cannot continue without required packages: $packages"
  fi
}

make_scripts_executable() {
  local script

  for script in ./*.sh; do
    if [[ -f "$script" ]]; then
      chmod +x "$script"
    fi
  done

  ok "Shell scripts are executable"
}

print_header() {
  printf "\n"
  printf "%s%s==> yt-dlp-media-tools installer (v%s)%s\n" "$BOLD" "$BLUE" "$VERSION" "$RESET"
  printf "%s\n" "    Safe one-line setup for macOS"
  printf "%s\n" "    -----------------------------"
}

# ----------------------------------------------------------------------------
# Bootstrap mode
#
# This lets the installer be run directly via:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
#
# without the user having to manually clone the repository first. If the
# script is not being run from inside an existing checkout (SCRIPT_NAME is
# missing in the current directory), it clones/updates the project into
# INSTALL_DIR and re-runs itself from there.
# ----------------------------------------------------------------------------
bootstrap_and_install() {
  step "Preparing one-line install"
  ok "Running in one-line install mode"
  info "Install location: $INSTALL_DIR"

  if ! command_exists git || ! command_runs git --version; then
    warn "git is required to download the project and is not installed or not working."
    confirm_install_packages git
    install_packages git
  fi

  if ! command_runs git --version; then
    fail "git is installed but did not run correctly. Install/fix git, then run this installer again."
  fi

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Existing installation found, updating to the latest version..."
    if ! git -C "$INSTALL_DIR" pull --ff-only; then
      warn "The existing install could not be updated safely."
      note "This usually means there are local edits or the branch cannot fast-forward."
      note "Inspect it with:"
      printf "\n  cd %s\n  git status\n\n" "$INSTALL_DIR"
      note "If you want to keep local edits, commit or stash them first."
      note "If you do not need them, remove the install folder and run this installer again."
      fail "Update stopped before changing your local files."
    fi
  elif [[ -e "$INSTALL_DIR" ]]; then
    fail "$INSTALL_DIR already exists and is not a git repository. Remove it or set YTMT_INSTALL_DIR to a different path, then try again."
  else
    info "Cloning repository into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  exec bash "./install.sh"
}

# ----------------------------------------------------------------------------
# Local install (runs once we are inside the project directory, either
# because the user cloned it manually or because bootstrap_and_install
# cloned it and re-exec'd this script)
# ----------------------------------------------------------------------------
setup_global_command() {
  local target="$PWD/$SCRIPT_NAME"

  mkdir -p "$BIN_DIR"
  ln -sf "$target" "$BIN_DIR/$COMMAND_NAME"
  ok "Created command '$COMMAND_NAME' -> $target"

  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
    persist_line "export PATH=\"$BIN_DIR:\$PATH\""
  fi
}

verify_required_tools() {
  local yt_dlp_version

  if ! yt_dlp_version="$(yt-dlp --version 2>/dev/null)"; then
    fail "yt-dlp is installed but did not run correctly. Try updating or reinstalling it, then run this installer again."
  fi

  if ! ffmpeg -version >/dev/null 2>&1; then
    fail "ffmpeg is installed but did not run correctly. Try updating or reinstalling it, then run this installer again."
  fi

  ok "Verified yt-dlp ($yt_dlp_version) and ffmpeg"
}

run_local_install() {
  local missing=()

  step "Preparing local files"
  make_scripts_executable

  step "Checking required tools"
  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      missing+=("$item")
    fi
  done < <(missing_commands)

  if [[ "${#missing[@]}" -eq 0 ]]; then
    ok "yt-dlp and ffmpeg are already installed"
  else
    warn "Missing packages: ${missing[*]}"
    confirm_install_packages "${missing[@]}"
    install_packages "${missing[@]}"
  fi

  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      fail "$item is still missing after installation. Please install it manually."
    fi
  done < <(missing_commands)

  verify_required_tools

  step "Creating the global command"
  setup_global_command

  printf "\n"
  log "installation complete"
  printf "%s==> Done%s\n" "$BOLD$GREEN" "$RESET"
  ok "Installation complete"
  printf "Start the tool:\n\n"
  printf "  %s\n\n" "$COMMAND_NAME"
  printf "To update yt-dlp: brew upgrade yt-dlp\n\n"

  if [[ "${PROFILE_UPDATED:-0}" -eq 1 ]] && [[ -t 0 ]] && [[ -t 1 ]] && [[ "${YTMT_NO_SHELL_RELOAD:-0}" != "1" ]]; then
    info "Reloading your shell so '$COMMAND_NAME' works right away..."
    exec "${SHELL:-/bin/bash}" -l
  fi
}

main() {
  local os_name

  print_header
  log "install started (v$VERSION)"

  step "Checking operating system"
  os_name="$(uname -s)"

  if [[ "$os_name" != "Darwin" ]]; then
    fail "Unsupported operating system: $os_name. This project now supports macOS only."
  fi

  ok "Detected system: macOS"
  log "macOS detected"

  ensure_macos_command_line_tools
  ensure_homebrew
  log "command line tools + Homebrew ready"

  if [[ -f "$SCRIPT_NAME" ]]; then
    run_local_install
  else
    bootstrap_and_install
  fi
}

main "$@"
