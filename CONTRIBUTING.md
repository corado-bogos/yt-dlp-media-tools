# Contributing

Thank you for your interest in `yt-dlp-media-tools`.

This is a personal learning project, but bug reports, suggestions, and pull requests are welcome. Please read this document before submitting anything.

---

## Table of Contents

- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Submitting Code](#submitting-code)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [License](#license)

---

## Reporting Bugs

Before opening a bug report:

1. Make sure you are on the latest version — re-run the one-line installer to update
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for a known fix
3. Search [existing issues](https://github.com/corado-bogos/yt-dlp-media-tools/issues) to avoid duplicates

When opening a new issue, include:

- Your macOS version (e.g. macOS 14.5)
- The exact steps that triggered the bug
- The full terminal output, including any error messages
- What you expected to happen

---

## Suggesting Features

Open an issue with the label `enhancement` and describe:

- What the feature would do
- Why it would be useful
- Any tradeoffs or edge cases you can think of

---

## Submitting Code

1. Fork the repository and create a branch from `main`
2. Make your changes
3. Test on macOS — this project supports macOS only
4. Open a pull request with a clear description of what changed and why

Keep pull requests focused — one change per PR makes review easier.

---

## Code Style

This project uses Bash. Please follow these conventions:

- Use `#!/usr/bin/env bash` as the shebang line
- Enable strict mode: `set -euo pipefail` (installer) or `set -o pipefail` (main script)
- Quote all variables: `"$VAR"` not `$VAR`
- Prefer `[[ ... ]]` over `[ ... ]` for conditionals
- Use `command -v name >/dev/null 2>&1` to check for commands
- Name functions with lowercase and underscores: `my_function()`
- Keep functions small and single-purpose
- Add a short comment above any non-obvious block

---

## Commit Messages

Use the imperative mood and keep the subject line under 72 characters.

**Format:**

```
<type>: <short description>

Optional longer explanation if needed.
```

**Types:**

| Type | Use for |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `refactor` | Code changes that are not a fix or feature |
| `chore` | Maintenance tasks (dependencies, formatting) |

**Examples:**

```
feat: add back navigation between steps
fix: handle empty URL input without exiting
docs: rewrite README installation section
refactor: extract cookie prompt into separate function
chore: update yt-dlp to latest version
```

---

## License

By contributing, you agree that your changes will be licensed under the same terms as the rest of the project. See [LICENSE.md](LICENSE.md) for details.