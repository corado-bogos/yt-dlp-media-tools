#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${YTMT_INSTALL_DIR:-$HOME/.local/share/yt-dlp-media-tools}"
BIN_DIR="${YTMT_BIN_DIR:-$HOME/.local/bin}"
COMMAND_NAME="ytmt"
STEP_NUMBER=0

PROFILE_BLOCK_START="# >>> yt-dlp-media-tools installer >>>"
PROFILE_BLOCK_END="# <<< yt-dlp-media-tools installer <<<"

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
  printf "  %s[ERROR]%s %s\n" "$RED" "$RESET" "$1"
  exit 1
}

step() {
  STEP_NUMBER=$((STEP_NUMBER + 1))
  printf "\n%s==> Step %s: %s%s\n" "$BOLD$BLUE" "$STEP_NUMBER" "$1" "$RESET"
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

shell_profile_files() {
  # Mirror install.sh: detect the current shell and emit only the profiles that
  # the installer would have written to. This prevents the uninstaller from
  # touching files it never modified.
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

is_safe_install_dir() {
  local path="$1"

  case "$path" in
    ""|"/"|"$HOME"|"$HOME/"|"$BIN_DIR"|"$BIN_DIR/")
      return 1
      ;;
  esac

  case "$path" in
    "$HOME"/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

remove_profile_block() {
  local file="$1"
  local temp_file

  [[ -f "$file" ]] || return 0

  if ! grep -qF "$PROFILE_BLOCK_START" "$file" 2>/dev/null; then
    return 0
  fi

  if ! grep -qF "$PROFILE_BLOCK_END" "$file" 2>/dev/null; then
    warn "Found installer start marker without end marker in $file; leaving it unchanged"
    return 0
  fi

  temp_file="$(mktemp "${TMPDIR:-/tmp}/ytmt-profile.XXXXXX")" || fail "Could not create a temporary file"

  awk -v start="$PROFILE_BLOCK_START" -v end="$PROFILE_BLOCK_END" '
    $0 == start { skipping = 1; next }
    $0 == end { skipping = 0; next }
    skipping != 1 { print }
  ' "$file" > "$temp_file"

  cat "$temp_file" > "$file"
  command rm -f "$temp_file"
  ok "Removed installer block from $file"
}

remove_global_command() {
  local command_path="$BIN_DIR/$COMMAND_NAME"

  if [[ -L "$command_path" ]]; then
    command rm -f "$command_path"
    ok "Removed command symlink: $command_path"
  elif [[ -e "$command_path" ]]; then
    warn "$command_path exists but is not a symlink; leaving it unchanged"
  else
    ok "Command symlink already absent: $command_path"
  fi
}

remove_install_dir() {
  if [[ ! -e "$INSTALL_DIR" ]]; then
    ok "Install folder already absent: $INSTALL_DIR"
    return 0
  fi

  if ! is_safe_install_dir "$INSTALL_DIR"; then
    fail "Refusing to remove unsafe install path: $INSTALL_DIR"
  fi

  command rm -rf "$INSTALL_DIR"
  ok "Removed install folder: $INSTALL_DIR"
}

clean_shell_profiles() {
  local file

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    remove_profile_block "$file"
  done < <(shell_profile_files)
}

print_header() {
  printf "%s%s==> yt-dlp-media-tools uninstaller%s\n" "$BOLD" "$BLUE" "$RESET"
  printf "%s\n" "    Removes the local install, global command, and shell profile block"
  printf "%s\n" "    ---------------------------------------------------------------"
}

main() {
  print_header

  info "Install folder: $INSTALL_DIR"
  info "Command path: $BIN_DIR/$COMMAND_NAME"

  if ! prompt_yes_no "Uninstall yt-dlp-media-tools?"; then
    warn "Uninstall cancelled."
    exit 0
  fi

  step "Removing the global command"
  remove_global_command

  step "Removing shell profile entries"
  clean_shell_profiles

  step "Removing install folder"
  remove_install_dir

  printf "\n"
  printf "%s==> Done%s\n" "$BOLD$GREEN" "$RESET"
  ok "yt-dlp-media-tools was uninstalled"
  printf "Restart your terminal, or run 'hash -r', if your shell still remembers '%s'.\n" "$COMMAND_NAME"
}

main "$@"
