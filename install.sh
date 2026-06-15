#!/usr/bin/env bash

set -euo pipefail

VERSION="1.1.0"
SCRIPT_NAME="yt-dlp-media-tools.sh"
REQUIRED_COMMANDS=(yt-dlp ffmpeg)

REPO_URL="https://github.com/corado-bogos/yt-dlp-media-tools.git"
INSTALL_DIR="${YTMT_INSTALL_DIR:-$HOME/.local/share/yt-dlp-media-tools}"
BIN_DIR="${YTMT_BIN_DIR:-$HOME/.local/bin}"
COMMAND_NAME="ytmt"

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
  printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$1"
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

command_exists() {
  command -v "$1" >/dev/null 2>&1
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
  info "Using Homebrew: $brew_path"
  return 0
}

install_with_homebrew() {
  local packages=("$@")
  local brew_path

  if ! setup_homebrew_path; then
    fail "Homebrew is required on macOS. Install it first, then run the Homebrew PATH commands shown at the end of its installer."
  fi

  brew_path="$(command -v brew)"
  info "Installing missing packages with Homebrew: ${packages[*]}"
  "$brew_path" install "${packages[@]}"
}

sudo_command() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    if ! command_exists sudo; then
      fail "sudo is required to install packages on this Linux system."
    fi
    sudo "$@"
  fi
}

install_with_linux_package_manager() {
  local packages=("$@")

  if command_exists apt-get; then
    info "Installing missing packages with apt: ${packages[*]}"
    sudo_command apt-get update
    sudo_command apt-get install -y "${packages[@]}"
  elif command_exists dnf; then
    info "Installing missing packages with dnf: ${packages[*]}"
    sudo_command dnf install -y "${packages[@]}"
  elif command_exists pacman; then
    info "Installing missing packages with pacman: ${packages[*]}"
    sudo_command pacman -Sy --needed --noconfirm "${packages[@]}"
  elif command_exists zypper; then
    info "Installing missing packages with zypper: ${packages[*]}"
    sudo_command zypper install -y "${packages[@]}"
  else
    fail "No supported Linux package manager found. Install the missing tools manually: ${packages[*]}"
  fi
}

install_packages() {
  local os_name="$1"
  shift
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    return 0
  fi

  case "$os_name" in
    Darwin)
      install_with_homebrew "${packages[@]}"
      ;;
    Linux)
      install_with_linux_package_manager "${packages[@]}"
      ;;
    *)
      fail "Unsupported operating system: $os_name"
      ;;
  esac
}

confirm_install_packages() {
  local packages="$*"
  local answer

  if [[ "${YTMT_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    fail "Missing packages need to be installed: $packages. Re-run in an interactive terminal or set YTMT_ASSUME_YES=1."
  fi

  printf "Install missing packages now? (%s) [y/N]: " "$packages"
  if ! read -r answer; then
    fail "Cannot continue without confirmation to install required packages: $packages"
  fi

  case "$answer" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      fail "Cannot continue without required packages: $packages"
      ;;
  esac
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
  printf "%s%syt-dlp-media-tools installer (v%s)%s\n" "$BOLD" "$BLUE" "$VERSION" "$RESET"
  printf "%s\n" "--------------------------------------"
}

display_system_name() {
  case "$1" in
    Darwin) printf "macOS\n" ;;
    Linux) printf "Linux\n" ;;
    *) printf "%s\n" "$1" ;;
  esac
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
  local os_name="$1"

  info "Running in one-line install mode"
  info "Install location: $INSTALL_DIR"

  if [[ "$os_name" == "Darwin" ]]; then
    setup_homebrew_path || warn "Homebrew was not found in PATH or common install locations."
  fi

  if ! command_exists git; then
    warn "git is required to download the project and is not installed."
    confirm_install_packages git
    install_packages "$os_name" git
  fi

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Existing installation found, updating to the latest version..."
    git -C "$INSTALL_DIR" pull --ff-only
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
    warn "$BIN_DIR is not in your PATH yet."
    printf "Add this line to your shell config (~/.bashrc, ~/.zshrc, etc.) and restart your terminal:\n\n"
    printf "  export PATH=\"%s:\$PATH\"\n\n" "$BIN_DIR"
    PATH_NEEDS_SETUP=1
  else
    PATH_NEEDS_SETUP=0
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
  local os_name="$1"
  local missing=()

  make_scripts_executable

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
    install_packages "$os_name" "${missing[@]}"
  fi

  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      fail "$item is still missing after installation. Please install it manually."
    fi
  done < <(missing_commands)

  verify_required_tools
  setup_global_command

  printf "\n"
  ok "Installation complete"
  printf "Project location: %s\n\n" "$PWD"

  if [[ "${PATH_NEEDS_SETUP:-0}" -eq 1 ]]; then
    printf "After updating your PATH, restart your terminal or run:\n\n"
    printf "  source ~/.bashrc  # or source ~/.zshrc\n\n"
    printf "Then start the tool from anywhere with:\n\n"
  else
    printf "Start the tool from anywhere with:\n\n"
  fi
  printf "  %s\n\n" "$COMMAND_NAME"
  printf "(or run %s./%s%s from inside %s)\n\n" "$BOLD" "$SCRIPT_NAME" "$RESET" "$PWD"
}

main() {
  local os_name

  print_header

  os_name="$(uname -s)"
  info "Detected system: $(display_system_name "$os_name")"

  if [[ "$os_name" != "Darwin" && "$os_name" != "Linux" ]]; then
    fail "Unsupported operating system: $os_name"
  fi

  if [[ -f "$SCRIPT_NAME" ]]; then
    run_local_install "$os_name"
  else
    bootstrap_and_install "$os_name"
  fi
}

main "$@"
