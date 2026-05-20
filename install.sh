#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="yt-dlp-media-tools.sh"
REQUIRED_COMMANDS=(yt-dlp ffmpeg)

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
    fail "No supported Linux package manager found. Install yt-dlp and ffmpeg manually."
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
  printf "%s%syt-dlp-media-tools installer%s\n" "$BOLD" "$BLUE" "$RESET"
  printf "%s\n" "--------------------------------"
}

display_system_name() {
  case "$1" in
    Darwin) printf "macOS\n" ;;
    Linux) printf "Linux\n" ;;
    *) printf "%s\n" "$1" ;;
  esac
}

main() {
  local os_name
  local missing=()

  print_header

  if [[ ! -f "$SCRIPT_NAME" ]]; then
    fail "Could not find $SCRIPT_NAME. Run this installer from the project folder."
  fi

  os_name="$(uname -s)"
  info "Detected system: $(display_system_name "$os_name")"

  make_scripts_executable

  if [[ "$os_name" == "Darwin" ]]; then
    setup_homebrew_path || warn "Homebrew was not found in PATH or common install locations."
  fi

  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      missing+=("$item")
    fi
  done < <(missing_commands)

  if [[ "${#missing[@]}" -eq 0 ]]; then
    ok "yt-dlp and ffmpeg are already installed"
  else
    warn "Missing packages: ${missing[*]}"

    case "$os_name" in
      Darwin)
        install_with_homebrew "${missing[@]}"
        ;;
      Linux)
        install_with_linux_package_manager "${missing[@]}"
        ;;
      *)
        fail "Unsupported operating system: $os_name"
        ;;
    esac
  fi

  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      fail "$item is still missing after installation. Please install it manually."
    fi
  done < <(missing_commands)

  printf "\n"
  ok "Installation complete"
  printf "Start the tool with:\n\n"
  printf "  ./%s\n\n" "$SCRIPT_NAME"
}

main "$@"
