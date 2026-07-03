# Troubleshooting

Common fixes for `yt-dlp-media-tools` on macOS.

For anything not listed here: https://github.com/corado-bogos/yt-dlp-media-tools/issues

---

## Installation

**One-line install fails**

Check that `curl` works, then try again:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

---

**Stuck on "Finish the Apple installation window..."**

A popup appeared from Apple. Switch to it, click **Install**, wait for it to finish, then press **Enter** in Terminal.

---

**`Missing command: yt-dlp`**

```bash
brew install yt-dlp
```

Or reinstall `ytmt` to pull in its dependencies again:

```bash
brew reinstall ytmt
```

---

**`ffmpeg was not found`**

All modes require `ffmpeg`.

```bash
brew install ffmpeg
```

---

**`brew: command not found`**

Homebrew is installed but not on your PATH. Fix for Apple Silicon:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

For Intel Mac, replace `/opt/homebrew` with `/usr/local`.

---

## Startup

**`ytmt: command not found`**

`ytmt` is installed by Homebrew, so it needs Homebrew's `shellenv` on your PATH. Open a new Terminal window, or run:

```bash
eval "$(brew shellenv)"
```

To make it permanent, add that line to `~/.zprofile` (Apple Silicon default location: `/opt/homebrew/bin/brew`; Intel: `/usr/local/bin/brew`).

---

**`Permission denied: ./yt-dlp-media-tools.sh`**

```bash
chmod +x yt-dlp-media-tools.sh
```

---

## Downloads

**Download fails immediately**

- Make sure the URL points to a public video or playlist
- Try selecting a browser in the cookie menu (options 1–5 instead of 0)
- Update yt-dlp: `brew upgrade yt-dlp`

---

**`ERROR: Sign in to confirm you're not a bot`**

Select a browser from the cookie menu. Make sure you are logged into YouTube in that browser and not in a private/incognito window.

---

**Download is slow**

YouTube rate-limits downloads. Wait a few minutes and try again. Browser cookies (options 1–5) can help bypass rate limits.

---

**Same files download again**

The archive file (`archive.txt` in your save folder) tracks completed downloads. If it was deleted or you changed folders, the tool has no record of previous downloads.

To reset: delete `archive.txt`. To disable tracking: choose **No** at the archive prompt on startup.

---

## Cookies

**Cookies cannot be loaded**

- Make sure the browser is open and you are logged into YouTube
- Do not use private or incognito mode — those cookies are not accessible
- Try a different browser

---

**Safari cookies not working**

Safari requires Full Disk Access for Terminal.

**System Settings → Privacy & Security → Full Disk Access → enable Terminal**

Alternatively, use Chrome, Firefox, Brave, or Edge.

---

## Output

**Thumbnails not embedded**

Verify `ffmpeg` is installed: `ffmpeg -version`. If missing: `brew install ffmpeg`.

WEBM saves thumbnails as separate `.jpg` files. FLAC does not include thumbnails.

---

**Keep the full yt-dlp log**

```bash
YTMT_KEEP_LOG=1 ytmt
```

The log is saved as `ytmt-last-run.log` in your download folder.

---

## Updates and uninstall

**Update the tool**

```bash
brew upgrade ytmt
```

---

**Uninstall**

```bash
brew uninstall ytmt
brew untap corado-bogos/tap
```

---

**Removing an old (pre-1.3.0) install**

Versions before 1.3.0 cloned the project into `~/.local/share` and symlinked `ytmt` into `~/.local/bin`. If you still have one of those installs, remove it manually:

```bash
rm -rf ~/.local/share/yt-dlp-media-tools
rm -f ~/.local/bin/ytmt
```

Then remove the installer block from `~/.zprofile` or `~/.bashrc` if present:

```text
# >>> yt-dlp-media-tools installer >>>
...
# <<< yt-dlp-media-tools installer <<<
```
