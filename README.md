# dotfiles

Personal workstation bootstrap + dotfile templates for Fedora and Ubuntu.

Despite the name, this repo is **two things in one**:

1. **Bootstrap scripts** (`scripts/`) — run-once installers that turn a fresh
   Fedora or Ubuntu desktop into "mine". They install packages, register
   VS Code, configure GNOME, set up zsh + oh-my-zsh, install Docker CE
   rootless mode, etc. They mostly run once per machine; re-running is
   safe.
2. **Dotfile templates** (`home/`) — actual tracked dotfiles
   (`~/.gitconfig`, `~/.tmux.conf`, `~/.vimrc`, etc.) that get installed
   into `$HOME` by `install-home.sh`.

Homelab-coupled stuff (NFS mounts to `m910q`, LAN `/etc/hosts`, systemd
services that rclone to `/mnt/nfs/raid1-camelot`, the syncthing and yt-vpn
docker stacks) lives in the separate **homelab** repo, not here. If you
need those, see there.

## Quick start on a fresh machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles

# 1. Bootstrap: install packages, configure shell, register VS Code, etc.
./bootstrap.sh

# 2. Install dotfiles into $HOME.
./install-home.sh
```

Run each script's `--help` for fine-grained control. For example, to
just install Docker:

```bash
./bootstrap.sh --only docker --yes
```

## Layout

```
dotfiles/
├── README.md                       # this file
├── LICENSE                          # GPL-3.0
├── .gitignore
├── .shellcheckrc                    # shellcheck config for CI
├── bootstrap.sh                     # orchestrator: runs scripts/ in order
├── install-home.sh                  # dotfile installer
├── lib/
│   └── detect-distro.sh             # exports DISTRO, PKG_INSTALL, etc.
├── scripts/
│   ├── README.md                    # script run order + notes
│   ├── setup-basics.sh              # core CLI tools, VS Code, fonts, Spotify
│   ├── setup-gnome.sh               # GNOME theme, fonts, animations, nautilus
│   ├── setup-zsh.sh                 # zsh + oh-my-zsh + plugins + kafeitu theme
│   ├── setup-docker.sh              # Docker CE + rootless setuptool
│   ├── setup-python.sh              # pip
│   ├── setup-rclone.sh              # rclone
│   ├── purge-docker.sh              # destructive: uninstall Docker
│   └── zshrc-additions.sh           # small aliases — source from ~/.zshrc
├── vscode/
│   └── settings.json                # copied into ~/.config/Code/User/
├── screen-baby-profiles/
│   └── screenset.sh                 # monitor brightness modes (normal/baby)
└── home/                            # dotfiles tracked under real names
    ├── .gitconfig
    ├── .gitignore_global
    ├── .tmux.conf
    ├── .vimrc
    └── .ssh/
        └── config.template          # rendered into ~/.ssh/config
```

## Distro support

| Distro   | Status      | Notes                                              |
| -------- | ----------- | -------------------------------------------------- |
| Fedora   | Primary     | Tested on Fedora 41.                               |
| Ubuntu   | Supported   | Tested on Ubuntu 24.04. Some Fedora-only packages  |
|          |             | (e.g. `dnfdragora`, `celluloid`) are skipped.      |
| Debian   | Best-effort | Same code path as Ubuntu. Not actively tested.     |
| Other    | Not tested  | `lib/detect-distro.sh` will report "unknown".      |

`lib/detect-distro.sh` is the single source of truth: it reads
`/etc/os-release`, exports `DISTRO`, `PKG_INSTALL`, `PKG_UPDATE`,
`PKG_QUERY`, and `PKG_REPO_ADD`. Scripts that need different package
names or commands between distros branch on `$DISTRO`.

## How scripts are run

`scripts/setup-*.sh` are standalone — each can be invoked directly. They
all start with:

```bash
set -euo pipefail
. "$(dirname "$0")/../lib/detect-distro.sh"
```

and use `$PKG_INSTALL` for package installs where the command is the
same across distros, branching on `$DISTRO` only where package names or
commands genuinely differ (VS Code repo add, GNOME font packages, Docker
GPG setup, etc.).

`bootstrap.sh` is a thin orchestrator that runs them in the documented
order:

```
setup-basics → setup-gnome → setup-zsh → setup-docker → setup-python → setup-rclone
```

This order matters: `setup-basics` installs git, gh, vim, VS Code, fonts;
`setup-zsh` and `setup-gnome` need fonts; `setup-docker` needs the apt
repo configuration from `setup-basics`. See `scripts/README.md` for
detail.

## How dotfiles are installed

`install-home.sh` walks `home/` and, for each file, either:

- **symlinks it** to `$HOME/<filename>` (e.g. `home/.vimrc` →
  `~/.vimrc`); or
- **renders** a `.template` file into its target with `__VAR__` →
  env-var substitution (e.g. `home/.ssh/config.template` →
  `~/.ssh/config`).

Existing targets are backed up to `<target>.bak.<UTC-timestamp>` before
overwrite (skip with `--force`). Re-runs are idempotent: a symlink that
already points at the right source is left alone.

Useful env vars:

| Var                          | Purpose                                | Default            |
| ---------------------------- | -------------------------------------- | ------------------ |
| `DOTFILES_SSH_USERNAME`      | `__USERNAME__` in ssh config template  | `$USER`            |
| `DOTFILES_SSH_HOMELAB_HOST`  | `__HOMELAB_HOST__` placeholder         | `homelab`          |

Example:

```bash
DOTFILES_SSH_USERNAME=alice DOTFILES_SSH_HOMELAB_HOST=nas.local ./install-home.sh
```

## Adding a new bootstrap script

1. Create `scripts/setup-<name>.sh`. Start with:
   ```bash
   #!/bin/bash
   set -euo pipefail
   . "$(dirname "$0")/../lib/detect-distro.sh"
   ```
2. Use `$PKG_INSTALL` for package installs. Branch on `$DISTRO` only when
   you need to (different package names, different repo setup, etc.).
3. Add the script name to the `ORDER` array in `bootstrap.sh`.
4. Document it in `scripts/README.md`.
5. Run `bash -n scripts/setup-<name>.sh` and (if shellcheck is installed)
   `shellcheck scripts/setup-<name>.sh`.

## Adding a new dotfile

1. Add the file under `home/` with the exact name it should have in
   `$HOME` (e.g. `home/.zshrc`). For files that live in a subdirectory
   of `$HOME` (e.g. `~/.ssh/config`), use `home/.ssh/config.template`.
2. If the file has personal values that vary by machine, use
   `__UPPERCASE_PLACEHOLDER__` and add a substitution line to
   `install-home.sh`'s `render_template` function.
3. Test with `./install-home.sh --dry-run`, then run for real.

## What's NOT in this repo

- **Homelab infrastructure** (NFS exports, Docker stacks, router
  config, tailscale setup) → see the `homelab` repo.
- **Obsidian vault, KeePass DB, any actual config with secrets** →
  never committed.
- **Per-machine local overrides** — use `*.local` files; they're
  gitignored.

## CI / lint

`.github/workflows/shellcheck.yml` runs `shellcheck` on every push and PR
across `scripts/**/*.sh`, `lib/*.sh`, `bootstrap.sh`, and
`install-home.sh`. Locally: `shellcheck scripts/**/*.sh lib/*.sh
bootstrap.sh install-home.sh`.

`.shellcheckrc` enables `quote` and `deprecation` by default.

## License

GPL-3.0. See [LICENSE](LICENSE).