# yt-dlp-media-tools

A beginner-friendly macOS terminal tool for downloading videos and audio from YouTube and other platforms. Wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) in a simple step-by-step interface — no commands to memorize.

[![Shell](https://img.shields.io/badge/shell-bash-blue)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)](#install)
[![Version](https://img.shields.io/badge/version-v1.2.1-brightgreen)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Personal%20Use-green)](LICENSE.md)

> **macOS only.** Not tested or supported on Linux, Windows, or WSL.

---

## Install

Open Terminal and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

The installer handles everything: Apple Command Line Tools, Homebrew, `yt-dlp`, and `ffmpeg`. Each step asks before installing anything.

Then start from any terminal window:

```bash
ytmt
```

**Manual install:**

```bash
git clone https://github.com/corado-bogos/yt-dlp-media-tools
cd yt-dlp-media-tools
chmod +x install.sh
./install.sh
```

**Unattended install:**

```bash
YTMT_ASSUME_YES=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

> Piping `curl | bash` runs a remote script on your machine. Read [install.sh](install.sh) first if you prefer.

---

## Usage

The tool walks you through four steps: save location, URL, format, and browser cookies. Back and exit are available at every step.

---

## Formats

| # | Format | Type  | Thumbnail         |
|---|--------|-------|-------------------|
| 1 | MP4    | Video | Embedded          |
| 2 | WEBM   | Video | Saved as `.jpg`   |
| 3 | MP3    | Audio | Embedded          |
| 4 | M4A    | Audio | Embedded          |
| 5 | FLAC   | Audio | None              |

> FLAC is lossless but cannot improve quality beyond the original compressed source.

---

## Output

Files are saved to the folder you choose at startup. Playlist items include a zero-padded index:

```
001 - Artist - Title.mp3
002 - Artist - Title.mp3
```

---

## Archive tracking

After the first run, an `archive.txt` file is created in your save folder. Subsequent runs on the same URL skip already-downloaded items automatically. You can disable this at startup.

To reset: delete or move `archive.txt`.

---

## Update

Re-run the install command at any time:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

---

## Uninstall

```bash
~/.local/share/yt-dlp-media-tools/uninstall.sh
```

---

## Options

| Variable        | Default | Description                                          |
|-----------------|---------|------------------------------------------------------|
| `YTMT_KEEP_LOG` | `0`     | Set to `1` to save the full yt-dlp log to the download folder |
| `YTMT_ASSUME_YES` | `0`   | Set to `1` to auto-confirm installer prompts         |
| `YTMT_INSTALL_DIR` | `~/.local/share/yt-dlp-media-tools` | Installer: custom install directory |
| `YTMT_BIN_DIR` | `~/.local/bin` | Installer: custom directory for the `ytmt` symlink |

---

## Screenshots

![Choose save location](assets/01-save-location.png)

![Paste URL](assets/02-url.png)

![Choose download mode](assets/03-download-mode.png)

![Browser cookies](assets/04-browser-cookies.png)

![Starting download](assets/05-starting-download.png)

---

## Support

- Issues: https://github.com/corado-bogos/yt-dlp-media-tools/issues
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Contact: corado.dev@gmail.com

---

## License

Personal and educational use only. See [LICENSE.md](LICENSE.md).
