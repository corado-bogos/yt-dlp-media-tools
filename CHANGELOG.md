# Changelog

Version history for `yt-dlp-media-tools`.

## v1.0.0 - 2026-05-20

Initial public version.

### What This Version Can Do

- Download single videos.
- Download full playlists.
- Download video as `MP4`.
- Download video as `WEBM`.
- Download audio as `MP3`.
- Download audio as `M4A`.
- Download audio as `FLAC`.
- Use Desktop as the default download folder.
- Validate user input without closing immediately.
- Let users type `back` to return to the previous step.
- Let users type `exit` to close the program from any prompt.
- Show browser cookie choices as numbers.
- Ask before continuing without cookies when browser cookies cannot be loaded.
- Show a terminal progress bar during downloads.
- Ask if the user wants to continue after each download.
- Skip already-downloaded files with `archive.txt`.

### Browser Cookie Support

This version supports:

- `0` - Skip cookies
- `1` - Chrome
- `2` - Firefox
- `3` - Safari
- `4` - Edge
- `5` - Brave

Safari can work, but macOS may require Full Disk Access for Terminal.

### Thumbnail Behavior

| Format | Thumbnail behavior |
|---|---|
| `MP4` | Embedded when supported |
| `WEBM` | Saved separately as JPG |
| `MP3` | Embedded when supported |
| `M4A` | Embedded when supported |
| `FLAC` | No thumbnail |

### Installer

This version includes `install.sh`.

The installer can:

- Detect macOS or Linux.
- Show macOS as `macOS` instead of `Darwin`.
- Check if `yt-dlp` is installed.
- Check if `ffmpeg` is installed.
- Install missing dependencies when a supported package manager is available.
- Make shell scripts executable.

Supported package managers:

- macOS: `brew`
- Linux: `apt-get`, `dnf`, `pacman`, `zypper`

### Notes

- `FLAC` is lossless, but it does not improve the quality of the original source.
- `WEBM` mode uses only WEBM video and WEBM audio streams.
- The tool keeps `archive.txt` so repeated runs can skip already-downloaded files.
