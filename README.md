# yt-dlp-media-tools
Live site: https://yt-dlp-media-tools.netlify.app/

A beginner-friendly terminal downloader for videos, audio, and playlists, powered by `yt-dlp`.

![Shell](https://img.shields.io/badge/shell-bash-blue)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Version](https://img.shields.io/badge/version-v1.0.0-green)

## What It Does

`yt-dlp-media-tools` gives you a simple step-by-step terminal interface for downloading media without memorizing long `yt-dlp` commands.

It can download:

- Single videos
- Full playlists
- Video as `MP4` or `WEBM`
- Audio as `MP3`, `M4A`, or `FLAC`
- Restricted or rate-limited content with optional browser cookies

## How To Install

These steps are written for beginners. You only need to copy the commands for your system.

### Before You Copy Commands

#### 1. Open the Terminal app

On macOS, press `Command + Space`, type `Terminal`, and press `Enter`.

On Linux, open your normal terminal app.

#### 2. Copy a command

On GitHub, click the copy button in the top-right corner of a command box.

You can also click inside a command box, select the text, and press `Command + C` on macOS or `Ctrl + C` on Linux.

#### 3. Paste it into Terminal and run

Switch back to Terminal, paste the command, and press `Enter`.

Use `Command + V` on macOS or `Ctrl + Shift + V` on many Linux terminals.

#### 4. Follow the prompts

If Terminal asks for your password, type your computer login password and press `Enter`.

Password characters may not appear while you type. That is normal.

### macOS

#### Step 1 - Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Step 2 - Add Homebrew to Terminal

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### Step 3 - Check Homebrew

```bash
brew --version
```

If `brew` is still not found, close Terminal, open it again, and run `brew --version` one more time.

#### Step 4 - Install Git

```bash
brew install git
```

#### Step 5 - Download this project

```bash
git clone https://github.com/corado-bogos/yt-dlp-media-tools
cd yt-dlp-media-tools
```

#### Step 6 - Run the installer

```bash
chmod +x install.sh
./install.sh
```

#### Step 7 - Start the tool

```bash
cd yt-dlp-media-tools
./yt-dlp-media-tools.sh
```
Use this command every time you want to start the program. If it doesn’t work, first open the folder in the terminal and then run the program.

### Linux

#### Step 1 - Install Git

Debian / Ubuntu:

```bash
sudo apt update
sudo apt install git
```

Fedora:

```bash
sudo dnf install git
```

Arch:

```bash
sudo pacman -S git
```

#### Step 2 - Download this project

```bash
git clone https://github.com/corado-bogos/yt-dlp-media-tools
cd yt-dlp-media-tools
```

#### Step 3 - Run the installer

```bash
chmod +x install.sh
./install.sh
```

#### Step 4 - Start the tool

```bash
cd yt-dlp-media-tools
./yt-dlp-media-tools.sh
```
Use this command every time you want to start the program. If it doesn’t work, first open the folder in the terminal and then run the program.

## Installer

`install.sh` prepares the project for you.

It can:

- Detect macOS or Linux
- Check for `yt-dlp`
- Check for `ffmpeg`
- Install missing tools with a supported package manager
- Make shell scripts executable

Supported package managers:

- macOS: `brew`
- Linux: `apt-get`, `dnf`, `pacman`, `zypper`

## How To Use

Run:

```bash
cd yt-dlp-media-tools
./yt-dlp-media-tools.sh
```
Use this command every time you want to start the program. If it doesn’t work, first open the folder in the terminal and then run the program.
Then follow the terminal steps.

### 1. Save Folder

The default download folder is:

```text
~/Desktop
```

Press `Enter` to use Desktop, or paste another existing folder path.

You can type `back` on later steps to return to the previous step.

You can type `exit` at any prompt to close the program.

### 2. URL

Paste a video or playlist URL.

The URL must start with:

```text
http://
```

or:

```text
https://
```

If the URL is wrong, the tool asks again instead of closing.

### 3. Format

Choose a number:

```text
1) MP4   - Best video quality
2) WEBM  - Native YouTube quality, thumbnail saved separately
3) MP3   - Maximum compatibility
4) M4A   - Good audio quality
5) FLAC  - No thumbnail image; does not improve source quality
```

FLAC note: FLAC is lossless, but it cannot make YouTube or streaming audio better than the original source.

### 4. Browser Cookies

Choose a number:

```text
0) Skip cookies
1) Chrome
2) Firefox
3) Safari
4) Edge
5) Brave
```

Cookies are optional, but they can help with:

- Age-restricted videos
- Members-only content
- Private or login-required videos
- Large playlists
- YouTube rate limits

For most users, Chrome, Brave, Edge, or Firefox are recommended.

Safari can work, but macOS may require Full Disk Access for Terminal.

If browser cookies cannot be loaded, the tool asks if you want to download anyway without cookies.

## Output

Files are saved in the folder you selected.

Example:

```text
Desktop/
|-- 001 - Artist - Song Title.mp3
|-- 002 - Artist - Song Title.mp3
|-- 003 - Artist - Song Title.mp3
`-- archive.txt
```

`archive.txt` tracks already downloaded items so repeated runs can skip duplicates.

This tool does not save `yt-dlp-last-run.log`.

## Formats

| Option | Format | Best For | Thumbnail |
|---|---|---|---|
| 1 | MP4 | Most video players | Embedded when supported |
| 2 | WEBM | Native YouTube quality | Saved separately as JPG |
| 3 | MP3 | Cars, phones, speakers | Embedded when supported |
| 4 | M4A | Good quality, smaller files | Embedded when supported |
| 5 | FLAC | Lossless conversion from source | No thumbnail |

## Support

For bugs or questions, open an issue:

https://github.com/corado-bogos/yt-dlp-media-tools/issues

For common fixes, see:

[TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Private contact:

```text
corado.dev@icloud.com
```

## License

This project is for educational and personal use only.

See [LICENSE.md](LICENSE.md) for full terms.
