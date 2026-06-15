[README.md](https://github.com/user-attachments/files/28959666/README.md)
# 🎬 yt-dlp-media-tools

> A beginner-friendly terminal tool for downloading videos, audio, and playlists from YouTube and other platforms.

![Shell](https://img.shields.io/badge/shell-bash-blue) ![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey) ![License](https://img.shields.io/badge/license-Personal%20Use-green) ![Version](https://img.shields.io/badge/version-1.1.0-orange)

---

## 📌 Overview

**yt-dlp-media-tools** is a simple interactive shell script that wraps the powerful `yt-dlp` tool into an easy step-by-step experience — no technical knowledge required.

It lets you download:

- 🎬 videos (MP4, WEBM)
- 🎧 audio (MP3, M4A, FLAC)
- 📂 full playlists

Works on **macOS** and **Linux**.

---

## ✨ Features

✔ Interactive step-by-step prompts — no commands to memorize
✔ 5 download formats to choose from
✔ Automatically names files with index, artist, and title
✔ Skips already-downloaded files automatically (`archive.txt`)
✔ Embeds thumbnails and metadata into every file
✔ Retries failed downloads automatically
✔ Validates your input at every step
✔ Run from anywhere with a single `ytmt` command after install

---

## ⚙️ Requirements

- macOS or Linux
- Terminal
- Internet connection

The installer checks for `git`, `yt-dlp`, and `ffmpeg`. If anything is missing, it asks before installing packages with your system package manager.

---

## 🚀 Quick install (recommended)

Open Terminal and paste this single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

This one line will:

✔ Detect your operating system (macOS or Linux)
✔ Use Homebrew on macOS if it is already installed
✔ Ask before installing `git`, `yt-dlp`, and `ffmpeg` if missing
✔ Download the project into `~/.local/share/yt-dlp-media-tools`
✔ Create a global command called **`ytmt`**, runnable from any folder

> 💡 **Why `~/.local/share`?** It's a hidden, standard location for app data — it won't show up in Finder/Files by default and won't get deleted by accident. To remove the tool later, see [Uninstall](#️-uninstall).

> 🔒 **Security tip:** Piping `curl | bash` runs a remote script directly. If you'd rather review the code first, open the [install.sh source](https://github.com/corado-bogos/yt-dlp-media-tools/blob/main/install.sh) or use the manual installation below.

Once it finishes, start the tool from **any** terminal window with:

```bash
ytmt
```

> If you see a warning about your `PATH`, follow the one-line instruction it prints (add `~/.local/bin` to your `PATH`), then restart your terminal or run `source ~/.bashrc` / `source ~/.zshrc`. After that, `ytmt` will work everywhere.

---

## 🛠️ Manual installation

If you prefer to clone the repository yourself first (e.g. to inspect the code before running anything):

### Step 1 — Clone the repository

```bash
git clone https://github.com/corado-bogos/yt-dlp-media-tools
cd yt-dlp-media-tools
```

> 💡 If you don't have `git` yet, install it first:
>
> - **Mac:** `brew install git` (requires [Homebrew](https://brew.sh))
> - **Linux:** `sudo apt-get install git`

### Step 2 — Run the installer

```bash
chmod +x install.sh
./install.sh
```

The installer will automatically:

✔ Detect your operating system (macOS or Linux)
✔ Use Homebrew on macOS if it is already installed
✔ Ask before installing `yt-dlp` and `ffmpeg` if missing
✔ Skip tools that are already installed
✔ Verify that `yt-dlp` and `ffmpeg` can run
✔ Make the main script executable
✔ Create the global `ytmt` command pointing at this folder

---

## 🔄 Updating

Re-run the same one-line install command at any time:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/corado-bogos/yt-dlp-media-tools/main/install.sh)"
```

It detects the existing installation in `~/.local/share/yt-dlp-media-tools`, pulls the latest changes with `git pull --ff-only`, and re-runs the installer to refresh dependencies and the `ytmt` command. If you changed files locally in that folder, commit, stash, or remove those changes before updating.

If you used the manual install, just run `git pull` followed by `./install.sh` from inside your cloned folder.

---

## 🗑️ Uninstall

Everything lives in two predictable places, so removal is a couple of terminal commands:

```bash
rm -rf ~/.local/share/yt-dlp-media-tools
rm -f ~/.local/bin/ytmt
```

If you added the `export PATH=...` line to your shell config during install, you can remove it too (optional).

---

## ▶️ Usage

After installation, run from anywhere:

```bash
ytmt
```

(or `./yt-dlp-media-tools.sh` from inside the project folder if you used the manual install without the global command)

The tool will guide you through 3 simple steps.

---

## 📌 How it works

### 📁 Step 1 — Choose save location

You will see:

```
Paste your save location:
```

Type or paste the path to an existing folder on your Mac.

**Examples:**

```
/Users/yourname/Music
~/Music
~/Downloads
```

> 💡 **Mac tip:** Open Finder → go to your folder → hold **Option** → right-click → **Copy as Pathname** → paste into Terminal.

If the folder doesn't exist, the tool will show an error and stop.

---

### 🔗 Step 2 — Paste your URL

You can paste:

- A single video link
- A single audio link
- A full playlist link

> The URL must start with `http://` or `https://` — otherwise the tool will show an error.

---

### 🎛️ Step 3 — Choose download mode

```
1) 🎬 MP4  - Best video quality
2) 🌐 WEBM - Native YouTube quality
3) 🎧 MP3  - Maximum compatibility
4) 🎵 M4A  - Good audio quality
5) 🔥 FLAC - Converted lossless
```

Type a number (1–5) and press **Enter**.

---

## 🎬 Video modes

| Mode | Format | What it does |
| --- | --- | --- |
| 1 | MP4 | Downloads best video + best audio and merges them |
| 2 | WEBM | Downloads native YouTube quality without re-encoding |

Both modes embed the thumbnail and metadata automatically.

---

## 🎧 Audio modes

| Mode | Format | Best for |
| --- | --- | --- |
| 3 | MP3 | Universal compatibility — cars, phones, speakers |
| 4 | M4A | Good quality with smaller file size |
| 5 | FLAC | Highest quality, larger files |

All audio modes extract the best available audio source and embed thumbnail and metadata.

---

## 📂 Output structure

Files are saved in the folder you selected, named automatically:

```
Music/
 ├── 001 - Artist - Song Title.mp3
 ├── 002 - Artist - Song Title.mp3
 ├── 003 - Artist - Song Title.mp3
```

---

## 🔁 Re-running the tool

The tool creates an `archive.txt` file in your save folder after the first run. This file tracks what has already been downloaded — so running the tool again on the same playlist will skip files you already have.

---

## ⚠️ macOS permissions

The first time you run this tool, macOS may ask:
> *"Terminal wants to access data from other applications"*

✔ Click **Allow**
✔ Enter your password if prompted

This is required for reading browser cookies.

---

## 🔐 Browser note

This tool uses **Chrome** browser cookies by default (`--cookies-from-browser chrome`).

To avoid issues:

✔ Make sure **Google Chrome** is installed
✔ Keep Chrome open while downloading
✔ Do **not** use private / incognito mode

> Browser cookies help bypass rate limits and allow downloading age-restricted or large playlists reliably.

---

## 🔥 Possible upgrades

- GUI / app-style interface (no Terminal needed)
- Support for additional browsers (Firefox, Safari)
- Automatic yt-dlp update check on launch

---

## 📄 License

This project is for **personal and educational use only.**
See [LICENSE.md](LICENSE.md) for full terms.
