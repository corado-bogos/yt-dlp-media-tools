# Security Policy

## Supported Versions

This project is actively maintained in a single main version.

Only the latest version of the repository (main branch) is supported.

| Version | Supported |
| ------- | --------- |
| main    | :white_check_mark: |
| older commits / forks | :x: |

---

## Important Security Notice

This project is a shell-based tool that uses `yt-dlp` and system-level commands.

Because of this:

- It executes commands on your local machine
- It may access external URLs provided by the user
- It can optionally use browser cookies for authentication

You are fully responsible for:
- Input URLs you provide
- Files downloaded
- System changes caused by scripts

---

## Unsupported Use Cases

This project does NOT support or encourage:

- Downloading copyrighted content without permission
- Use against platform terms of service
- Redistribution of pirated media
- Automated abuse of third-party services

---

## Cookies & Authentication Security

If you use browser cookies:

- Cookies are read locally from your system
- They are NOT uploaded anywhere by this project
- They remain your responsibility to secure

We recommend:
- Using temporary cookies when possible
- Avoiding sharing cookie files
- Deleting cookies after use

---

## Reporting a Vulnerability

If you discover a security issue, please report it **privately** — do not open a public issue, as that would disclose the problem before it can be fixed.

Preferred channels:

- **GitHub private vulnerability reporting**: go to the repository's **Security** tab → **Report a vulnerability**.
- **Email**: corado.dev@gmail.com

When reporting, please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Any relevant logs or screenshots

---

## Response Time

Security reports will typically be reviewed within:
- 1–5 days (depending on severity and availability)

Critical issues may be prioritized.

---

## Security Updates

Security-related fixes may involve updates to:

- project scripts (`.sh` files)
- dependency tools (`yt-dlp`, `ffmpeg`)
- configuration handling

Users are advised to keep their local copy updated.

---

## Disclaimer

This project is provided "as is" without any warranty.

The maintainers are not responsible for:
- misuse of the tool
- user-provided content
- external dependency behavior
