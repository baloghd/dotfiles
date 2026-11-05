---
name: herdr
description: >-
  Herdr GUI mods and layouts: custom panels, right-side Files/Changes-style
  stacks, layout JSON, mod.clone, herdr-app check/shot. Use when the user asks
  to change Herdr, add a herdr-app panel/mod, edit ~/.config/herdr-app, or
  mentions herdr layouts/tabs/workspace.panels.
---

# Herdr panels and layouts

Primary docs (read before inventing APIs; this skill is only the short workflow):

- `herdr-app --skill` / `hc --skill` — official agent manuals
- `~/.config/herdr-app/AGENTS.md` — full local guide (rewritten every start)
- `~/.config/herdr-app/herdr.d.ts`, `gpui-kit.d.ts`
- Longer notes (this repo): `docs/research/herdr-custom-panels.md`

## What you edit

| Path | Role |
|---|---|
| `layouts/<name>.json` | Window tree (personal clones only for structure) |
| `mods/<name>/main.js` + `mod.json` | Panel code |
| `keys.json` | Keybinds |
| `settings.json` | Look (fonts, theme, zoom) |
| `shared.json` | Cross-mod state (e.g. `workspace.panels`) |

Shipped layouts/mods are replaced on start. Clone before changing structure or code:

```sh
herdr-app do layout.clone '{"name":"main","as":"my-layout"}'
herdr-app do mod.clone '{"name":"tabs","as":"tabs-metrics"}'
```

Editing a shipped file moves it to `<name>-edited` on the next start.

## Right-side panel like Files / Changes

Files and Changes are stack children under `panel` → `panel-body` in the main layout. To add another:

1. Create `mods/<name>/` with `mod.json` `{ "place": "none", "title": "…" }` and a `View` in `main.js`.
2. Add a block to the personal layout's `panel-body` stack (`id` = mod name, `content.mod` = folder).
3. Clone `tabs` (it hardcodes panel buttons) and add a `panelButton` gated on `shared("workspace.panels")`.
4. Point the layout's tabs block at the clone.
5. Append the panel id to `shared.json` → `workspace.panels` (layout switches can drop custom ids; personal `tabs-*` clones should hardcode their extra button).
6. Open with `layout.select` + `layout.show`, or the new tab-bar button.
7. Install herdr-app files as **copies**, not symlinks (`install-home` does this): herdr reloads on real-file writes and misses symlink-target updates.

```sh
herdr-app do layout.select '{"stack":"panel-body","child":"<id>"}'
herdr-app do layout.show '{"id":"panel"}'
```

## Mod rules (from AGENTS.md)

- Default-export a `View`. Use `cx.timer` / `cx.spawn`; never `setTimeout` or top-level `await`.
- Never keep a `cx` across callbacks.
- No HTML/CSS/DOM/Node. UI is gpui-kit (`div`, `v_flex`, `h_flex`, …).
- Remote work: `exec(cmd, args, { on: machineName })` and `readTextFile(path, { on })`. `machines()` lists cores (`name: null` = this computer).
- Hot reload on save. Broken save keeps the old build; check `herdr-app status` → `errors`.

## Done criteria

```sh
herdr-app check ~/.config/herdr-app/mods/<name>
herdr-app shot /path/in/project/out/herdr-shot.png   # inspect UI; put under project out/, not /tmp
```

Never call a mod done without a passing `check`. Prefer a `shot` when the change is visual.

## Existing personal pieces (Dobamo)

- Layout: `main-usage` (clone of `main`; left usage strip + right panels).
- Mods: `usage` (sidebar meters), `metrics` (right panel: CPU/RAM per `machines()` host, ‹ › nav), `tabs-metrics` (Files/Changes/Metrics buttons).
- Dotfiles track copy: `git-repos/dotfiles` branch/worktree `feat/herdr-usage-panel` under `home/.config/herdr-app/`.
