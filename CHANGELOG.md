# Changelog

All notable changes to `yt-dlp-media-tools` are documented here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) conventions.

---

## [v1.1.0] — 2026-06-16

macOS-focused release with a full installer rewrite, one-line install support, a global `ytmt` command, and an improved download script.

### Highlights

- Added one-line install via `curl | bash` — sets up everything from scratch on a clean Mac
- Added bootstrap mode — the installer clones or updates the project automatically without requiring a manual `git clone` first
- Added the global `ytmt` command in `~/.local/bin`, runnable from any folder after install
- Changed project scope to **macOS only** — Linux installer branches removed
- All installer steps now ask `[y/N]` before installing anything
- Added `YTMT_ASSUME_YES=1` for fully unattended installs

---

### Installer (`install.sh`)

**Added**

- One-line install via `curl | bash` — run directly from the GitHub `main` branch without cloning first
- Bootstrap mode — when run outside the project folder, the installer clones into `~/.local/share/yt-dlp-media-tools` and re-runs itself from there
- Update support — re-running the one-line command on an existing install runs `git pull --ff-only` instead of re-cloning
- Global `ytmt` command — created as a symlink in `~/.local/bin` pointing to the installed script
- `YTMT_INSTALL_DIR` — override the default install location
- `YTMT_BIN_DIR` — override where the `ytmt` symlink is placed
- `YTMT_ASSUME_YES=1` — auto-confirms all installer prompts; also passes `NONINTERACTIVE=1` to Homebrew when installing it
- Apple Command Line Tools check — if missing, offers to run `xcode-select --install`, opens the Apple popup, and waits before continuing
- Homebrew check — if missing, offers to run the official Homebrew installer and configures `shellenv` immediately after
- Explicit `[y/N]` confirmation before installing each package (Apple CLT, Homebrew, `git`, `yt-dlp`, `ffmpeg`)
- `verify_required_tools()` — confirms `yt-dlp` and `ffmpeg` actually run after installation, not just that they exist in `PATH`
- Shell profile persistence — Homebrew `shellenv` and `PATH` additions written inside a marked `# >>> yt-dlp-media-tools installer >>>` block, deduplicated across runs
- macOS-only OS validation — exits with a clear message on non-Darwin systems
- Improved `git pull --ff-only` failure handling — stops with clear instructions instead of a raw Git error

**Changed**

- Homebrew detection now searches `/opt/homebrew/bin/brew` (Apple Silicon) and `/usr/local/bin/brew` (Intel) in addition to `$PATH`
- All shell scripts in the project directory made executable in a single loop
- Colored output: `->` label for info, `==> Step N:` format for step headers

**Removed**

- Linux package manager support (`apt-get`, `dnf`, `pacman`, `zypper`)
- Linux OS support — the installer now fails immediately on non-macOS systems

---

### Download Script (`yt-dlp-media-tools.sh`)

**Added**

- `ffmpeg` presence check at startup — warns before any download begins if `ffmpeg` is missing
- `ffmpeg` enforcement per mode — modes that require it refuse to start if it is unavailable
- Optional full-run logging with `YTMT_KEEP_LOG=1` — saves `yt-dlp` output as `ytmt-last-run.log` in the selected download folder
- Cookie check separated into access failure vs. inconclusive result — each case handled with a distinct message and action
- Improved output template — handles playlist index and single-video filenames gracefully; uses a safe fallback when artist or uploader metadata is missing
- Homebrew and `~/.local/bin` added to `PATH` at startup — prevents false "command not found" errors in fresh terminal sessions

**Changed**

- Step labels updated to `1/4`, `2/4`, `3/4`, `4/4` to reflect the correct 4-step flow

---

### Documentation

- Updated Quick Install to use the one-line `curl` command
- Updated Usage section to reflect 4 steps (save location, URL, download mode, browser cookies)
- Added Updating and Uninstall sections
- Clarified that the license is a custom personal/educational-use license, not OSI-approved

---

## [v1.0.0] — 2026-05-20

Initial public release.

### Added

**Download capabilities**

- Download single videos and full playlists
- Download video as `MP4` or `WEBM`
- Download audio as `MP3`, `M4A`, or `FLAC`

**Interface**

- Interactive step-by-step terminal prompts — no commands to memorize
- `back` navigation — type `back` at any step to return to the previous one
- `exit` command — type `exit` at any prompt to close the tool
- Input validation at every step — invalid entries re-prompt instead of closing the tool
- Desktop as the default save folder when no path is entered
- Browser cookie selection by number (0–5)
- Confirmation prompt after cookie load failure — ask whether to continue without cookies
- Terminal progress bar during active downloads
- Prompt after each download asking whether to continue

**Download behavior**

- Files named automatically as `001 - Artist - Title.ext`
- Archive tracking via `archive.txt` — already-downloaded files skipped on repeated runs
- Thumbnails and metadata embedded automatically
- Automatic retry on failed downloads (up to 20 attempts)

**Browser cookie support**

| Option | Browser |
|---|---|
| `0` | Skip cookies |
| `1` | Chrome |
| `2` | Firefox |
| `3` | Safari |
| `4` | Edge |
| `5` | Brave |

> Safari may require Full Disk Access for Terminal on macOS.

**Thumbnail behavior by format**

| Format | Behavior |
|---|---|
| `MP4` | Embedded when supported |
| `WEBM` | Saved separately as `.jpg` |
| `MP3` | Embedded when supported |
| `M4A` | Embedded when supported |
| `FLAC` | Not embedded |

**Installer (`install.sh`)**

- Detects macOS, displays `macOS` instead of raw kernel name `Darwin`
- Checks for `yt-dlp` and `ffmpeg`, installs missing tools via `brew`
- Makes all shell scripts executable

### Notes

- FLAC is lossless but cannot improve quality beyond the original compressed source
- WEBM mode uses only WEBM video and WEBM audio streams
- `archive.txt` is created in the save folder after the first run and persists across sessions

---