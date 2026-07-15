# scripts/

Standalone bootstrap scripts. All source `lib/detect-distro.sh` and use
`$PKG_INSTALL` / `$PKG_UPDATE` for cross-distro package management.

## Run order

Defined in `bootstrap.sh`'s `ORDER` array:

| #  | Script                  | What it does                                                                                                  |
| -- | ----------------------- | ------------------------------------------------------------------------------------------------------------- |
| 1  | `setup-basics.sh`       | git/gh/vim, openssh-server, VS Code repo + extensions, fonts, Spotify, sox, NFS client, FUSE, KeePassXC, ripgrep |
| 2  | `setup-gnome.sh`        | Dark theme, GNOME Tweaks, fonts (Noto on Fedora, Inter on Ubuntu), animations, hot corners, nautilus-copy-path |
| 3  | `setup-zsh.sh`          | zsh + oh-my-zsh + zsh-syntax-highlighting + zsh-autosuggestions + autojump + kafeitu theme + `chsh` to zsh     |
| 4  | `setup-docker.sh`       | Docker CE from official repo + uidmap + rootless setuptool                                                    |
| 5  | `setup-python.sh`       | `python3-pip`                                                                                                  |
| 6  | `setup-rclone.sh`       | `rclone`                                                                                                       |

Standalone (not in default run order):

| Script                  | Notes                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------ |
| `purge-docker.sh`       | Destructive. Removes Docker entirely. Never run from `bootstrap.sh`; run by hand only.                       |
| `zshrc-additions.sh`    | Two-line alias snippet. Not a setup script — source it from `~/.zshrc`, or append its contents there.        |

## Why this order

- **`setup-basics` first**: installs git, gh, the Microsoft GPG key, and
  fonts that later steps (gnome, zsh) depend on.
- **`setup-gnome` after basics**: depends on `gnome-tweaks` and font
  packages installed by basics.
- **`setup-zsh` after basics**: oh-my-zsh installer clones from GitHub,
  which needs git from basics; the plugin clones also benefit from a
  working git config (`baloghd` / `baloghd@sent.com` is set by basics).
- **`setup-docker` after basics**: VS Code repo + Microsoft GPG key are
  added by basics; Docker uses a similar pattern.
- **`setup-python`, `setup-rclone` last**: tiny, dependency-free, safe to
  run anywhere.

## Running a subset

`bootstrap.sh` accepts `--only` and `--skip`:

```bash
./bootstrap.sh --only docker --yes          # only setup-docker.sh
./bootstrap.sh --skip gnome --skip docker  # everything except those two
```

Or invoke any script directly:

```bash
bash scripts/setup-zsh.sh
```

## When scripts differ from their original fedora/ubuntu versions

Before refactor, this repo contained parallel `fedora/` and `ubuntu/`
trees with copies of these scripts. They were collapsed using
`lib/detect-distro.sh`. Differences that survived are:

| Where                                                          | Why branched                                                                 |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `setup-basics.sh` — VS Code repo add (rpm vs apt+gpg)         | Repo setup syntax differs (dnf config-manager vs sources.list + signed-by).   |
| `setup-basics.sh` — Spotify (flatpak vs apt)                   | Ubuntu prefers deb repo; Fedora uses flathub.                                |
| `setup-basics.sh` — Celluloid vs gnome-mpv, Noto vs Inter     | Different default packages between distros.                                  |
| `setup-docker.sh` — repo GPG setup                             | Fedora uses `dnf config-manager`, Ubuntu needs sources.list + signed-by.     |
| `setup-gnome.sh` — `org.gnome.shell.ubuntu color-scheme`       | Ubuntu-specific schema; harmless no-op on Fedora.                            |
| `setup-gnome.sh` — font package set                            | Inter / IBM Plex on Ubuntu, Noto on Fedora.                                  |
| `setup-zsh.sh` — autojump init file path                       | `/usr/share/autojump/autojump.zsh` (Fedora) vs `autojump.sh` (Debian/Ubuntu).|

If you add a new script, prefer `$PKG_INSTALL` over branching whenever
the package names happen to match. Branch only when they don't.

## Style

- `set -euo pipefail` at the top of every script.
- Always source the detect helper first.
- `chmod +x` every script.
- Pass `bash -n scripts/*.sh` before committing.