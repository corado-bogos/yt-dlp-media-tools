# CHANGELOG

All notable changes to `yt-dlp-media-tools` are documented here.

---

## [v1.2.2] — 2026-07-03

### Added

- **Homebrew install** — the tool can now be installed via a Homebrew tap: `brew install corado-bogos/tap/ytmt` (installs `yt-dlp` and `ffmpeg` automatically). README documents this as the recommended method, alongside the existing one-line installer.
- **`## Legal` section in the README** — a short, visible notice: the tool is legal software, the user is responsible for downloaded content and for respecting copyright and platform terms, and it is not affiliated with YouTube, Google, or any supported platform.
- **One-time legal notice at install time** — `install.sh` now prints a copyright-responsibility reminder at the end of installation; the Homebrew formula shows the same notice via `caveats`.

### Changed

- **Liability disclaimer consolidated** — the disclaimer text was duplicated in `LICENSE.md` and `SECURITY.md`. `LICENSE.md` is now the single canonical source; `SECURITY.md`'s `## Disclaimer` points to it. The `Unsupported Use Cases` section in `SECURITY.md` is unchanged.
- Version bumped to `v1.2.2`.

---

## [v1.2.1] — 2026-07-02

### Fixed

- **`exit` at the archive prompt** — typing `exit` at the "Skip already-downloaded files?" step (1/4) now quits the program, matching every other prompt. Previously it was treated as a normal answer and the wizard continued.

- **Empty-array crash under `set -u`** — since `set -u` was added in beta.1, expanding an empty array (`"${COOKIE_ARGS[@]}"`, `"${_YTMT_TEMP_FILES[@]}"`) aborted the script with `unbound variable` on the stock macOS bash 3.2. This crashed the most common path — downloading with cookies skipped — right before the download started, and also broke the `EXIT` cleanup trap. Both expansions are now guarded with `${arr[@]+"${arr[@]}"}`.
- **Temp files were never cleaned up** — `create_temp_file` was only ever called via command substitution (`$(create_temp_file)`), so its `_YTMT_TEMP_FILES+=(...)` append ran in a subshell and was discarded. The parent array stayed empty and the `EXIT`/`INT` cleanup trap removed nothing, leaking temp files into `$TMPDIR`. The helper now stores the path in `_YTMT_LAST_TEMP_FILE` and is called directly, so tracking and cleanup work as intended. (As a side effect, a failed `mktemp` now correctly aborts the program instead of only the subshell.)
- **Output path bug** — files were saved to the shell's working directory instead of the user-selected folder. The yt-dlp `-o` template now always uses the full absolute path (`$MUSIC_PATH/...`).
- **Safari cookie warning** — the warning about Full Disk Access now appears only if Safari cookie extraction actually fails, never proactively.
- **URL validation** — the previous check (`^https?://`) accepted bare domains and known non-downloadable YouTube paths. Validation now rejects short links (e.g. `https://youtu.be`), YouTube homepages, feed pages, and search result pages.
- **`--no-keep-video` placement** — was incorrectly included in `COMMON_ARGS`, affecting video modes. Now only present in audio modes (MP3, M4A, FLAC).
- **`run_ytdlp` cookie detection** — added `operation not permitted` to the `^ERROR:` cookie-error pattern, matching the pattern already used by the pre-download cookie check.
- **`render_progress` error/warning matching anchored** — `ERROR:` and `WARNING:` are now matched only at the start of a line (`^ERROR:`, `^WARNING:`), so lines that merely mention those words mid-text are no longer coloured or treated as status.

### Changed

- **Archive tracking is now optional** — the user is asked at the save-location step whether to skip already-downloaded files.
- **Continue prompt simplified** — reduced from three options (`y/n/exit`) to two (`y/exit`).
- **yt-dlp update command detection** — inspects the yt-dlp binary path to recommend `brew upgrade`, `pipx upgrade`, or `pip3 install -U` depending on how it was installed. No longer recommends `yt-dlp -U` unconditionally.
- **`render_progress` output filter tightened** — all yt-dlp bracket-prefixed internal lines (e.g. `[youtube]`, `[download]`, `[Merger]`, `[EmbedThumbnail]`) are suppressed. Users see the progress bar, warnings, errors, and nothing else.
- **`--help` output rewritten** — shorter, now shows the supported formats, version and website. Note: it no longer lists the `YTMT_ASSUME_YES`, `YTMT_INSTALL_DIR`, and `YTMT_BIN_DIR` variables (still honoured by `install.sh`); only `YTMT_KEEP_LOG` is shown.
- **`VERSION` variable** — the main script now derives its `--help`/`--version` output from a single `VERSION` constant instead of hard-coded strings.
- **Cookie "Skip" option** — selecting `0` no longer prints a "no cookies selected" warning; it proceeds silently.
- **Back navigation** — stepping back now redraws the header for a cleaner screen.
- **Installer output simplified** — the final `install.sh` message drops the project-location/run-from-folder lines and now shows `To update yt-dlp: brew upgrade yt-dlp`.
- **Navigation hints** — replaced verbose instructions with `back • exit`.
- **README** — significantly reduced (137 lines, was 380).
- **TROUBLESHOOTING** — significantly reduced (194 lines, was 403).
- Version bumped to `v1.2.1` (first stable release of the 1.2.1 line).

---

## [v1.2.1-beta.2] — 2026-06-28

### Fixed

- `render_progress()` — removed dead `DOWNLOAD_HAS_ERRORS=1` assignment (runs in a subshell; assignments were discarded).
- `run_ytdlp()` — tightened cookie error detection to anchor grep to `^ERROR:` lines only.
- `download_once()` — removed `cd "$MUSIC_PATH"` (no longer needed since absolute archive path was fixed in beta.1).
- `uninstall.sh` — `shell_profile_files()` now mirrors installer shell-detection logic; no longer cleans profiles the installer never touched.

---

## [v1.2.1-beta.1] — 2026-06-18

### Fixed

- Added `set -u` — unset variables now cause an immediate error.
- `INT` trap moved to after `warn()` is defined.
- `--download-archive` uses absolute path (`"$MUSIC_PATH/archive.txt"`).
- Cookie check now shows feedback while waiting; `clear_line` after completion.
- Installer: separated `local packages` declaration from assignment (SC2178/SC2128).

### Added

- `--help` / `-h` flag.
- `--version` / `-v` flag.
- `uninstall.sh`.
- `.shellcheckrc` global SC2086 disable removed; warnings are now per-line where needed.

---

## [v1.2.0] — 2026-06-17

### Security

- Temporary files created with `chmod 600`.
- Automatic cleanup via `EXIT` and `INT` traps.
- URL character validation before passing to yt-dlp.

### Fixed

- Cookie vs. download error classification.
- ffmpeg warning shown once per session only.
- Log saved to `$MUSIC_PATH/ytmt-last-run.log`.
- Writability check on save folder before download.
- URL input trimmed of whitespace.
- Cookie/browser variables reset on re-prompt.

---

## [v1.1.1] — 2026-06-17

### Fixed

- `ensure_ffmpeg_available` was calling `fail()` (exits the program) instead of returning an error code, preventing mode re-selection.
- Cookie error grep was too broad — matched `WARNING:` lines mentioning "cookie", causing false `DOWNLOAD_HAS_ERRORS`.
- Playlist index template used raw index without zero-padding; corrected to `{:03d}`.
- README was missing two screenshot entries.
- CHANGELOG had mismatched version strings.

---

## [v1.1.0] — 2026-06-16

One-line install, global `ytmt` command, macOS-only scope.

- `curl | bash` installer with bootstrap mode (clones project automatically).
- `ytmt` symlink created in `~/.local/bin`.
- `YTMT_ASSUME_YES=1` for unattended installs.
- Shell profile persistence with deduplication.
- Startup ffmpeg check.
- `YTMT_KEEP_LOG=1` environment variable.

---

## [v1.0.0] — 2026-05-20

Initial public release.

- Download single videos and playlists as MP4, WEBM, MP3, M4A, or FLAC.
- Interactive 4-step terminal wizard.
- Browser cookie selection (Chrome, Firefox, Safari, Edge, Brave).
- Progress bar, archive tracking, thumbnail and metadata embedding.
- Desktop as default save folder.
