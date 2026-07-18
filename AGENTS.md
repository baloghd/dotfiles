# dotfiles — Agent Operating Manual

This file is for AI agents and humans alike. It codifies how work happens
in this repo.

## The one rule

**Never commit directly to `main`.** Always work on a feature branch and
open a PR — even for a one-line change. The branch is the review unit.

Why this matters here even though the repo is small and personal:

- Forces a deliberate commit boundary. Hard to accidentally couple two
  unrelated edits.
- Makes rollbacks one button (`gh pr close`).
- Keeps `git log --first-parent` meaningful.
- Gives CI a chance to actually gate something.

## Branch workflow

```bash
# 1. Branch from current main.
git fetch origin
git checkout -b <type>/<short-kebab-summary> origin/main

# 2. Make changes, commit (see commit conventions below).
git commit -m "feat(scripts): add setup-foo.sh"

# 3. Push and open a PR.
git push -u origin <branch>
gh pr create --base main --head <branch> --fill
# (edit the auto-generated title/body before submitting)

# 4. Wait for CI. Address any shellcheck failures.

# 5. Squash-merge once green.
gh pr merge --squash --delete-branch
```

### Branch naming

`<type>/<short-kebab-summary>` where `<type>` is one of:

| Type       | Use for                                       |
| ---------- | --------------------------------------------- |
| `feat`     | New scripts, new dotfiles, new capabilities   |
| `fix`      | Bug fixes, idempotency corrections            |
| `refactor` | Restructuring without behavior change         |
| `docs`     | README, AGENTS.md, comments                   |
| `chore`    | Tooling, CI, dependency bumps                 |

Examples: `feat/dotfiles-tmux-conf`, `fix/setup-hosts-idempotency`,
`refactor/dotfiles-reorg`, `docs/agents-md`.

## Commit conventions

Conventional Commits, one logical change per commit.

```
<type>(<scope>): <subject>

<optional body explaining why, not what>
```

- **Subject** ≤ 72 chars, imperative mood ("add", not "added"),
  no trailing period, no capitalized first letter after the colon.
- **Scope** (optional): the script, dotfile, or area affected
  (e.g. `setup-basics`, `install-home`, `bootstrap`, `ci`).
- **Body** explains *why*, not *what* — the diff shows what.

## CI

`.github/workflows/shellcheck.yml` runs on every push and PR:

- `bash -n` syntax check on every shell file
- `shellcheck --severity=warning` on every shell file

PRs must pass CI before squash-merge.

Local equivalents:

```bash
find scripts lib -name '*.sh' -print0 | xargs -0 -n1 bash -n
bash -n bootstrap.sh install-home.sh
shellcheck --severity=warning scripts/*.sh lib/*.sh bootstrap.sh install-home.sh
```

## Adding a bootstrap script

1. Create `scripts/setup-<name>.sh` starting with:
   ```bash
   #!/bin/bash
   set -euo pipefail
   . "$(dirname "$0")/../lib/detect-distro.sh"
   ```
2. Use `$PKG_INSTALL` for package installs. Branch on `$DISTRO` only
   when package names or commands genuinely differ (see the diff table
   in `scripts/README.md`).
3. Add the script name to the `ORDER` array in `bootstrap.sh`.
4. Document it in `scripts/README.md`.
5. Run the local CI equivalents above before committing.

## Adding a dotfile

1. Add the file under `home/` with the exact name it should have in
   `$HOME` (e.g. `home/.zshrc`). For files in subdirectories of `$HOME`
   (e.g. `~/.ssh/config`), use `home/.ssh/config.template`.
2. If the file has machine-specific values, use `__UPPERCASE__` and add
   the substitution to `install-home.sh`'s `render_template` function.
3. Test with `./install-home.sh --dry-run`.

## What NOT to commit

- **Homelab infrastructure** — see the `homelab` repo.
- **Secrets, API tokens, real SSH keys, KeePass DBs, Obsidian vaults.**
- **Machine-specific overrides** — use `*.local` files (gitignored).
- **Generated artifacts** under `home/.installed` (gitignored).

## Layout

```
dotfiles/
├── AGENTS.md                  # this file
├── README.md                  # user-facing overview
├── LICENSE                    # GPL-3.0
├── .gitignore
├── .shellcheckrc
├── .github/workflows/shellcheck.yml
├── bootstrap.sh               # orchestrator: runs scripts/ in order
├── install-home.sh            # dotfile installer
├── lib/
│   └── detect-distro.sh
├── scripts/
│   ├── README.md
│   ├── setup-*.sh
│   ├── purge-docker.sh
│   └── zshrc-additions.sh
├── vscode/
│   └── settings.json
├── screen-baby-profiles/
│   └── screenset.sh
└── home/
    ├── .gitconfig
    ├── .gitignore_global
    ├── .tmux.conf
    ├── .vimrc
    └── .ssh/
        └── config.template
```

## Recovering from a main commit

If you (or an agent) accidentally commit to `main`:

```bash
# Save the commit(s) on a branch.
git branch rescue/<topic> HEAD
# Reset main to origin.
git checkout main
git reset --hard origin/main
# Push the rescue branch and open a PR.
git push -u origin rescue/<topic>
gh pr create --base main --head rescue/<topic> --fill
```

The commits aren't lost — `git reflog` keeps them for 90 days, and the
rescue branch keeps them indefinitely.