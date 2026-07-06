<p align="center">
  <img src="assets/brand/readme-hero.png" alt="ytmt — yt-dlp media tools: download video &amp; audio, the simple way" width="100%">
</p>

# yt-dlp-media-tools

A beginner-friendly macOS terminal tool for downloading videos and audio from YouTube and other platforms. Wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) in a simple step-by-step interface — no commands to memorize.

> **Branding:** logo, social card, X/Twitter header, favicon and more live in [`assets/brand/`](assets/brand/) — all generated from HTML so the design stays consistent.

[![Shell](https://img.shields.io/badge/shell-bash-blue)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)](#install)
[![Version](https://img.shields.io/badge/version-v1.3.0-brightgreen)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Personal%20Use-green)](LICENSE.md)

> **macOS only.** Not tested or supported on Linux, Windows, or WSL.

---

## Legal

`yt-dlp-media-tools` is a personal, educational wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp) — legal software. **You are responsible** for what you download and for complying with copyright law and the terms of service of the source platform.

Not affiliated with YouTube, Google, or any supported platform.

See [LICENSE.md](LICENSE.md) and [SECURITY.md](SECURITY.md) for the full terms.

---

## Features

- **Guided wizard** — four steps (save location → URL → format → cookies), with back/exit at every step. No flags to memorize.
- **Video & audio** — download as MP4, WEBM, MP3, M4A, or FLAC (see [Formats](#formats)).
- **Playlists** — grabs whole playlists, numbering items with a zero-padded index.
- **Thumbnails & metadata** — embedded automatically where the format supports it.
- **Archive tracking** — re-runs skip already-downloaded items (optional; toggle at startup).
- **Browser cookies** — optional, for age-restricted or members-only content (Chrome, Firefox, Safari, Edge, Brave).
- **Clean progress** — a simple progress bar; yt-dlp's internal log noise is filtered out.

---

## Requirements

- **macOS** — Apple Silicon or Intel. Not supported on Linux, Windows, or WSL.
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** and **[ffmpeg](https://ffmpeg.org)** — installed automatically by either install method below; no manual setup needed.

---

## Install

```bash
brew install corado-bogos/tap/ytmt
```

This pulls in `yt-dlp` and `ffmpeg` automatically. The first time, Homebrew asks you to trust the tap — accept the prompt, or run `brew trust corado-bogos/tap` once.

### No Homebrew?

This bootstraps everything (Apple Command Line Tools, Homebrew, then `ytmt` itself), asking before each step:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

Then start from any terminal window:

```bash
ytmt
```

> Piping `curl | bash` runs a remote script on your machine. Read [install.sh](install.sh) first if you prefer. For unattended/scripted installs, prefix it with `YTMT_ASSUME_YES=1` (see [Options](#options)).

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

```bash
brew upgrade ytmt
```

---

## Uninstall

```bash
brew uninstall ytmt
brew untap corado-bogos/tap
```

---

## Options

| Variable        | Default | Description                                          |
|-----------------|---------|------------------------------------------------------|
| `YTMT_KEEP_LOG` | `0`     | Set to `1` to save the full yt-dlp log to the download folder |
| `YTMT_ASSUME_YES` | `0`   | Set to `1` to auto-confirm installer prompts         |

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
