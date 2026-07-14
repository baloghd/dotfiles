# PLAN — dotfiles refactor

## Context

The repo is named `dotfiles` but currently tracks **zero actual dotfiles** — it's a fresh-machine bootstrap kit (11 paired `setup-*.sh` scripts in `fedora/` and `ubuntu/`) plus a handful of shipped config directories. A structural review surfaced five real problems:

1. **All 11 setup scripts are duplicated** across `fedora/` and `ubuntu/`, differing only in `dnf` vs `apt` and a few distro-specific lines. Bug fixes land in one and forget the other.
2. **Homelab-coupled pieces live here**: `setup-mounts.sh` (NFS mounts to `m910q`), `setup-hosts.sh` (LAN `/etc/hosts`), the two `systemd/` services that rclone to `/mnt/nfs/raid1-camelot` and Dropbox, and `syncthing/` and `yt-vpn/` stacks. Per the user's stated split, these belong in the homelab repo.
3. **No top-level README, no orchestrator, no shellcheck, near-empty `.gitignore`.** The run order lives in the user's head.
4. **Stub files in awkward states**: `settings.sh` and `add-shell-aliases.sh` are 0–1 byte placeholders that `diff` reports as "different" between distros for no reason. `setup-hosts.sh` is non-idempotent (unconditional `>> /etc/hosts`).
5. **The repo name doesn't fit the contents.** User decision: keep the name, but actually start tracking real dotfiles so it earns the name.

Decisions already made:
- De-dupe via **single tree + distro-detection helper** (not a CI guard).
- **Move homelab-coupled pieces to the homelab repo**: `setup-mounts.sh`, `setup-hosts.sh`, the two `systemd/` services and their setup script, `syncthing/`, `yt-vpn/`.
- **Keep** personal bootstrap pieces: setup scripts, `vscode/settings.json`, `screen-baby-profiles/`, `purge-docker.sh`, shell snippets.
- **Add real dotfiles** under a `home/` directory, with a symlink/install helper.

## Approach

Reshape into:

```
dotfiles/
├── README.md                    # NEW: purpose, order, requirements
├── .gitignore                   # EXPAND
├── .shellcheckrc                # NEW
├── LICENSE                      # keep GPL-3.0
├── .github/workflows/shellcheck.yml   # NEW
├── bootstrap.sh                 # NEW: single entrypoint that runs setup-*.sh in order
├── lib/
│   └── detect-distro.sh         # NEW: sets $DISTRO, $PKG_INSTALL, $PKG_UPDATE
├── scripts/                     # NEW: collapsed from fedora/+ubuntu/
│   ├── setup-basics.sh
│   ├── setup-docker.sh
│   ├── setup-gnome.sh
│   ├── setup-python.sh
│   ├── setup-rclone.sh
│   ├── setup-zsh.sh
│   ├── purge-docker.sh
│   ├── zshrc-additions.sh       # keep — has real content
│   └── README.md                # documents the script order
├── home/                        # NEW: real dotfiles (templates)
│   ├── gitconfig
│   ├── gitignore_global
│   ├── tmux.conf
│   ├── ssh_config.template
│   └── vimrc
├── install-home.sh              # NEW: symlinks/copies home/* into $HOME (idempotent)
├── vscode/
│   └── settings.json
└── screen-baby-profiles/
    └── screenset.sh
```

**Distro-detection helper** (`lib/detect-distro.sh`):
- Detects via `/etc/fedora-release` vs `/etc/debian_version` (covers both Fedora and Ubuntu).
- Exports: `DISTRO`, `PKG_INSTALL` (e.g. `sudo dnf install -y` / `sudo apt-get install -y`), `PKG_UPDATE`, `PKG_QUERY`.
- Sources fine on bash and zsh.

**Script refactor pattern**: every `scripts/setup-*.sh` starts with `# shellcheck source=../lib/detect-distro.sh` + `. "$(dirname "$0")/../lib/detect-distro.sh"`, then uses `$PKG_INSTALL` for equivalent commands and `if [ "$DISTRO" = fedora ]; then ...; else ...; fi` only where packages or commands genuinely differ (e.g. gnome-tweaks vs gnome-tweaks + IBM Plex font name on Ubuntu).

**Stub cleanup**: delete `settings.sh` and `add-shell-aliases.sh` in both distros — they were 0–1 byte placeholders with no real content. If a need resurfaces, add it back deliberately.

**`.gitignore`** additions:
- `local-lan-hosts-mapping.txt` (defensive — no longer referenced here, but if it ever sneaks in)
- `home/.installed` (marker file used by `install-home.sh`)
- `*.local`
- `*.swp`, `*~`

**`bootstrap.sh`** is a tiny orchestrator that:
1. Sources `lib/detect-distro.sh` and prints the detected distro.
2. Runs `scripts/setup-basics.sh` first, then the rest in a documented order (docker, gnome, zsh, python, rclone).
3. Asks before running `purge-docker.sh` (it's destructive; should never auto-run).
4. At the end, offers to run `install-home.sh` (interactive, since dotfiles are personal).

**Real dotfiles under `home/`** — sensible starter set:
- `gitconfig` — user/email placeholder, common aliases (`co`, `br`, `st`), default editor, pull rebase.
- `gitignore_global` — OS cruft, editor swap files, common build dirs.
- `tmux.conf` — sane prefix binding, mouse on, 256 colors, sane status line.
- `ssh_config.template` — placeholder for Host blocks with `__USERNAME__` / `__HOSTNAME__` substitution.
- `vimrc` — minimal: line numbers, syntax on, expandtab, basic key bindings.

User can trim or expand during review. Each file lives as a real dotfile name so `install-home.sh` can symlink or copy with no transformation; the only templated one is `ssh_config.template` (rendered into `~/.ssh/config`).

**`install-home.sh`**:
- For each entry in `home/`:
  - If filename starts with `.`, target is `$HOME/$filename`.
  - If file ends in `.template`, render `__VAR__` → env value, write to target (no overwrite without `--force`).
  - Otherwise: symlink target → `home/$filename` (idempotent: `ln -sf`).
- Backs up any existing target to `target.bak.<timestamp>` before overwriting.
- `--dry-run` flag for first run.

## Files to modify / create / delete

**Create:**
- `README.md`
- `.shellcheckrc`
- `.github/workflows/shellcheck.yml`
- `bootstrap.sh`
- `install-home.sh`
- `lib/detect-distro.sh`
- `scripts/setup-basics.sh`, `setup-docker.sh`, `setup-gnome.sh`, `setup-python.sh`, `setup-rclone.sh`, `setup-zsh.sh`, `purge-docker.sh`, `zshrc-additions.sh`
- `scripts/README.md` (documents script order)
- `home/gitconfig`, `home/gitignore_global`, `home/tmux.conf`, `home/ssh_config.template`, `home/vimrc`

**Modify:**
- `.gitignore` — add `home/.installed`, `*.local`, editor swap files

**Delete** (from this repo — moves to homelab repo):
- `fedora/` and `ubuntu/` — entire trees
- After deletion, `fedora/screen-baby-profiles/screenset.sh` content is preserved by re-creating under `screen-baby-profiles/screenset.sh` at the repo root
- Stubs: `fedora/settings.sh`, `fedora/add-shell-aliases.sh`, `ubuntu/settings.sh`, `ubuntu/add-shell-aliases.sh` (just gone — no content to preserve)

**Move to homelab repo** (user does these in the homelab repo, after deleting here):
- `setup-mounts.sh`, `setup-hosts.sh`, `setup-own-systemd-services.sh`
- `systemd/obsidian-sync.service`, `systemd/pass-dropbox.service`
- `syncthing/` (docker-compose.yml, ports.sh, README.md; the stale `syncthing/config/` dir is just rm'd)
- `yt-vpn/` (alias.sh, docker-compose.yml)

## Reuse

- **`screen-baby-profiles/screenset.sh`** — currently a single file, no changes needed other than being moved up one level (from `fedora/screen-baby-profiles/` and `ubuntu/screen-baby-profiles/`, both byte-identical). Lift one copy to the repo root.
- **`vscode/settings.json`** — already distro-agnostic; lift one copy to repo root.
- **Syncthing and yt-vpn docker-compose files** — moving verbatim to the homelab repo; no transformation needed.
- **Systemd service templates** (`__USERNAME__` placeholder) — the `sed` substitution pattern in `setup-own-systemd-services.sh` is already correct; just moves to homelab.

## Steps

Phase 1 — **Scope cleanup** (move homelab bits out, independent)
- [ ] In homelab repo: create matching directories and copy in (don't symlink) `setup-mounts.sh`, `setup-hosts.sh`, `setup-own-systemd-services.sh`, `systemd/*.service`, `syncthing/{docker-compose.yml,ports.sh,README.md}`, `yt-vpn/{alias.sh,docker-compose.yml}`. Commit there first.
- [ ] Back in this repo: `git rm` the same files plus the now-empty `fedora/syncthing/config/` dir. Commit ("move homelab-coupled configs to homelab repo").

Phase 2 — **De-dupe to single tree**
- [ ] Create `lib/detect-distro.sh` with detection logic and exported vars. Test it on Fedora and Ubuntu in a VM or container if available; otherwise eyeball it.
- [ ] Create `scripts/` and lift the 8 surviving scripts (`setup-basics`, `setup-docker`, `setup-gnome`, `setup-python`, `setup-rclone`, `setup-zsh`, `purge-docker`, `zshrc-additions`) from `fedora/`, rewriting the package-manager lines to use `$PKG_INSTALL` / `$PKG_UPDATE`. Add `if [ "$DISTRO" = fedora ]; then …; fi` only where commands genuinely differ.
- [ ] Lift `vscode/settings.json` and `screen-baby-profiles/screenset.sh` to the repo root.
- [ ] `git rm -r fedora ubuntu` (now empty). Commit ("collapse fedora/ubuntu into single scripts/ tree").

Phase 3 — **Add real dotfiles**
- [ ] Create `home/{gitconfig,gitignore_global,tmux.conf,ssh_config.template,vimrc}` with placeholder values for user/email/hostnames.
- [ ] Create `install-home.sh` with idempotent symlink/copy logic, `--dry-run` flag, and timestamped backups.

Phase 4 — **Orchestration + polish**
- [ ] Create `bootstrap.sh` that sources the detect script and runs setup-*.sh in order, interactive for destructive steps.
- [ ] Create top-level `README.md` covering: purpose, two halves (`scripts/` + `home/`), distro support, run order, how to add a new script/dotfile, how to regenerate homelab bits.
- [ ] Create `scripts/README.md` documenting the run order.
- [ ] Create `.shellcheckrc` (`enable=quote,deprecation` is a sane starter) and `.github/workflows/shellcheck.yml` running `shellcheck scripts/**/*.sh lib/*.sh install-home.sh bootstrap.sh`.
- [ ] Expand `.gitignore`.
- [ ] Delete the stub files (already handled by `git rm -r fedora ubuntu`).

Phase 5 — **Verify** (see below).

## Verification

End-to-end check after each phase, and again at the end:

1. **Static checks** (in CI, also runnable locally):
   - `shellcheck scripts/**/*.sh lib/*.sh install-home.sh bootstrap.sh` — must pass.
   - `bash -n` on each script — must exit 0.
   - `test -z "$(git status --porcelain)"` after a clean clone + dry-run of `bootstrap.sh --dry-run` and `install-home.sh --dry-run`.

2. **Distro detection**:
   - On Fedora: `./bootstrap.sh --dry-run` prints "Detected: fedora" and the right `PKG_INSTALL`.
   - On Ubuntu: same, prints "Detected: ubuntu".

3. **Idempotency**:
   - Run `./install-home.sh` twice in a row. Second run should report "already linked, skipping" for each target, no backup files created.
   - For `setup-hosts.sh` (now in homelab): verify the moved version uses `grep -qxF` before appending (this is a fix to apply during the move).

4. **Bootstrap dry-run**:
   - On a fresh VM of each distro, run `bootstrap.sh --dry-run` end-to-end. Should complete without errors, just print the commands it would run.

5. **Manual smoke** (one real run on each distro, in a VM):
   - `bootstrap.sh` walks through setup-basics → setup-docker → setup-gnome → setup-zsh → setup-python → setup-rclone.
   - `install-home.sh` creates `~/.gitconfig`, `~/.tmux.conf`, `~/.vimrc`, `~/.ssh/config` (from template) with the placeholder values substituted.
   - Each new dotfile points to its source in the repo (verify with `ls -la ~/.gitconfig`).
   - Re-run `install-home.sh` → no changes, no backups created.

6. **Homelab sanity** (verify the move was clean):
   - In homelab repo: `setup-mounts.sh`, `setup-hosts.sh`, the systemd services, syncthing/, yt-vpn/ all present and unchanged.
   - In dotfiles repo: none of those paths exist; `git log --diff-filter=D --summary` shows them with the move commit.