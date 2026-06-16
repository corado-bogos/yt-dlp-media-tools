# Troubleshooting

Common fixes for `yt-dlp-media-tools` on macOS.

If your problem is not listed here, open an issue:
https://github.com/corado-bogos/yt-dlp-media-tools/issues

---

## Table of Contents

- [Installation Problems](#installation-problems)
- [Startup Problems](#startup-problems)
- [Download Problems](#download-problems)
- [Cookie Problems](#cookie-problems)
- [Output Problems](#output-problems)
- [Updating and Uninstalling](#updating-and-uninstalling)

---

## Installation Problems

---

**One-line install fails immediately**

Make sure `curl` works:

```bash
curl --version
```

If `curl` is missing or broken, fix your macOS command-line environment first, then run the installer again:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

---

**Unsupported operating system**

This project supports macOS only. The installer stops if `uname -s` is not `Darwin`.

---

**Stuck on "Finish the Apple installation window..."**

The installer checks for Apple Command Line Tools first. If they are missing and you confirm with `y`, it runs `xcode-select --install`, which opens a separate Apple popup window.

1. Switch to the popup window
2. Click **Install** and wait for it to finish
3. Go back to Terminal and press **Enter**

If the popup does not appear, run manually:

```bash
xcode-select --install
```

Then verify:

```bash
xcode-select -p
```

---

**Installer asks to install Homebrew**

This is expected on a clean Mac. Homebrew is used to install `git`, `yt-dlp`, and `ffmpeg`. Type `y` and press Enter when prompted. Homebrew may ask for your password and may take several minutes.

---

**Unattended install still prompts for something**

`YTMT_ASSUME_YES=1` auto-confirms this installer's own prompts:

```bash
YTMT_ASSUME_YES=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

The installer also passes `NONINTERACTIVE=1` to Homebrew when installing it. macOS may still require a password, Apple Command Line Tools interaction, or a permission approval depending on your system.

---

**`git is required to download the project`**

Type `y` when the installer asks to install `git`. If automatic installation fails, install it manually:

```bash
brew install git
```

Then run the installer again.

---

**`Missing command: yt-dlp`**

Run the installer again:

```bash
./install.sh
```

If it asks to install missing packages, type `y`. Manual fix:

```bash
brew install yt-dlp
yt-dlp --version
```

---

**`yt-dlp is installed but did not run correctly`**

Try updating or reinstalling:

```bash
brew update
brew upgrade yt-dlp
yt-dlp --version
```

Then run `./install.sh` again.

---

**`ffmpeg was not found`**

All download modes require `ffmpeg`. Run:

```bash
./install.sh
```

Manual fix:

```bash
brew install ffmpeg
ffmpeg -version
```

---

**`ffmpeg is installed but did not run correctly`**

Try reinstalling:

```bash
brew reinstall ffmpeg
ffmpeg -version
./install.sh
```

---

**`brew: command not found`**

The installer normally handles Homebrew PATH setup automatically. If Homebrew is installed but your shell cannot find it, set it up manually.

Apple Silicon:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Intel Mac:

```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Then verify:

```bash
brew --version
```

---

## Startup Problems

---

**`ytmt: command not found`**

The installer adds `~/.local/bin` to your shell profile. If the command is still missing after install, check your `PATH`:

```bash
echo $PATH
```

If `~/.local/bin` is not listed, add it manually:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To make it permanent, add the line above to `~/.zprofile` or `~/.bashrc`, or re-run:

```bash
./install.sh
```

Then restart Terminal or reload your shell:

```bash
exec "$SHELL" -l
```

---

**`Permission denied: ./yt-dlp-media-tools.sh`**

Make the script executable:

```bash
chmod +x yt-dlp-media-tools.sh
./yt-dlp-media-tools.sh
```

Running `./install.sh` also fixes this automatically.

---

## Download Problems

---

**Download fails immediately**

- Confirm the URL starts with `http://` or `https://`
- Confirm the video is publicly available — private videos cannot be downloaded even with cookies
- Try running with browser cookies (option 1–5 instead of 0)

---

**Some playlist items fail but others succeed**

This is normal. `yt-dlp` skips unavailable or deleted videos and continues. Successfully downloaded files are saved normally.

---

**`ERROR: Sign in to confirm you're not a bot`**

YouTube is requiring authentication. Select a browser from the cookie menu (options 1–5) instead of skipping. Make sure you are logged into YouTube in that browser and are not using private or incognito mode.

---

**Download is very slow**

YouTube occasionally rate-limits downloads. Wait a few minutes and try again. Using browser cookies (options 1–5) can also help bypass rate limits.

---

**The same files keep downloading again**

The tool creates `archive.txt` in your save folder to track completed downloads. If this file was deleted or you changed your save folder, the tool has no record of previous downloads and will start over. Keep `archive.txt` in place and always use the same save folder for the same playlist.

---

## Cookie Problems

---

**Cookies cannot be loaded**

- Make sure the browser you selected is open
- Make sure you are logged into YouTube in that browser
- Do not use private or incognito mode — cookies from those sessions are not accessible
- Try a different browser

---

**Safari cookies not working**

Safari requires Full Disk Access for Terminal to read its cookies.

Go to: **System Settings → Privacy & Security → Full Disk Access** → enable **Terminal**.

If you prefer not to change this setting, use Chrome, Brave, Edge, or Firefox instead.

---

**Cookies work but age-restricted videos still fail**

Make sure your YouTube account is logged in and old enough to access age-restricted content. YouTube enforces this server-side regardless of cookies.

---

## Output Problems

---

**Thumbnails are not embedded**

Make sure `ffmpeg` is installed:

```bash
ffmpeg -version
```

If not found, run `./install.sh` again.

Note: WEBM thumbnails are always saved as separate `.jpg` files — they are never embedded. FLAC does not embed or save thumbnails at all.

---

**File names have strange characters**

The tool uses `--windows-filenames` to remove characters that are invalid on Windows file systems. Some special characters in titles will be replaced or removed. This is expected.

---

**`archive.txt` is blocking a file you want to re-download**

Delete the relevant line from `archive.txt` in your save folder, or delete the entire file to reset download history for that folder.

---

**Keep the full yt-dlp output log**

Run the tool with:

```bash
YTMT_KEEP_LOG=1 ytmt
```

The log is saved as `ytmt-last-run.log` in your selected download folder.

---

## Updating and Uninstalling

---

**Existing install will not update**

The one-line installer updates with `git pull --ff-only`. If that fails, it means there are local edits or the branch cannot fast-forward.

Inspect the install folder:

```bash
cd ~/.local/share/yt-dlp-media-tools
git status
```

If you want to keep local edits, stash them first:

```bash
git stash
```

If you do not need them, remove the install folder and run the one-line installer again:

```bash
rm -rf ~/.local/share/yt-dlp-media-tools
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

---

**Install directory already exists but is not a git repo**

If you see:

```text
already exists and is not a git repository
```

Either remove the folder:

```bash
rm -rf ~/.local/share/yt-dlp-media-tools
```

Or use a different install location:

```bash
YTMT_INSTALL_DIR="$HOME/yt-dlp-media-tools" bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

---

**Full uninstall**

Remove the project and the global command:

```bash
rm -rf ~/.local/share/yt-dlp-media-tools
rm -f ~/.local/bin/ytmt
```

Then remove this block from your shell profile (`~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, or `~/.bashrc`) if it exists:

```text
# >>> yt-dlp-media-tools installer >>>
...
# <<< yt-dlp-media-tools installer <<<
```