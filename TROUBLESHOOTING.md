# Troubleshooting

Common fixes for `yt-dlp-media-tools`.

## `Missing command: yt-dlp`

Run the installer:

```bash
./install.sh
```

If it still fails, install `yt-dlp` manually.

macOS:

```bash
brew install yt-dlp
```

Linux:

```bash
sudo apt install yt-dlp
```

## `ffmpeg was not found`

Run the installer:

```bash
./install.sh
```

If it still fails, install `ffmpeg` manually.

macOS:

```bash
brew install ffmpeg
```

Linux:

```bash
sudo apt install ffmpeg
```

## `brew: command not found`

Homebrew may be installed but missing from your terminal `PATH`.

On most Apple Silicon Macs, run:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Then check:

```bash
brew --version
```

If it still fails, close Terminal, open it again, and try `brew --version` one more time.

## Permission Denied

If macOS says:

```text
permission denied: ./yt-dlp-media-tools.sh
```

Run:

```bash
chmod +x yt-dlp-media-tools.sh
./yt-dlp-media-tools.sh
```

The installer also does this automatically:

```bash
./install.sh
```

## Safari Cookie Error

Safari cookies can be blocked by macOS privacy permissions.

If Safari fails with:

```text
Operation not permitted
```

Use Chrome, Brave, Edge, or Firefox instead.

If you want to keep using Safari, give Terminal Full Disk Access:

```text
System Settings > Privacy & Security > Full Disk Access > Terminal
```

If cookies cannot be loaded, the tool asks if you want to continue without cookies.

Choose `y` if the video is public and does not require login.

## WEBM Has Problems

WEBM mode uses only WEBM video and WEBM audio streams.

WEBM thumbnails are saved separately as JPG files.

If a video does not provide good WEBM streams, use MP4 mode instead:

```text
1) MP4 - Best video quality
```

## FLAC Does Not Sound Better

FLAC is lossless, but it cannot improve the original source quality.

If the source is YouTube or another compressed stream, FLAC may create a larger file without better sound.

Use:

- `MP3` for maximum compatibility
- `M4A` for good quality and smaller files
- `FLAC` only when you specifically want lossless conversion from the available source

FLAC mode does not save or embed thumbnail images.

## Already Downloaded Files Are Skipped

The tool creates:

```text
archive.txt
```

This file remembers downloaded items.

If you want to download the same item again, remove its line from `archive.txt` or temporarily rename the file.
