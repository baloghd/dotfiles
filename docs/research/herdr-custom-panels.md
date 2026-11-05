# Herdr custom GUI panels / mods

Research notes for building right-side panels (Files/Changes style) and related mods.
Primary sources only. Written 2026-11-05.

## Sources

| Source | Role |
|---|---|
| [herdr.dev](https://herdr.dev/) | Product overview |
| [github.com/herdrdev/herdr-app](https://github.com/herdrdev/herdr-app) | App source / defaults |
| `~/.config/herdr-app/AGENTS.md` | Installed agent guide (rewritten every app start; same content as repo `defaults/AGENTS.md`) |
| `~/.config/herdr-app/herdr.d.ts` | Generated mod API types |
| `~/.config/herdr-app/mods/{files,changes,tabs,usage}/` | First-party / local examples |
| `herdr-app --skill`, `hc --skill` | Official CLI agent manuals |
| Live install: `herdr-app` 0.1.13, `hc` 0.1.18 | Verified on this machine |
| This worktree: `home/.config/herdr-app/mods/usage/`, `layouts/main-usage.json` | Existing custom usage panel |

---

## 1. What is Herdr? Where is source / docs?

**Herdr** is a native desktop app for terminals and coding agents. Two programs:

- **`herdr-app`**: the window (spaces, tabs, layouts, panels/mods).
- **`herdr-core` (`hc`)**: runs every terminal and agent; they keep running when the window closes or updates.

The whole UI is plain files under `~/.config/herdr-app` (or `$HERDR_APP_HOME`). Layouts, keys, settings, and JavaScript **mods** hot-reload. Mods describe **GPUI** UI via **gpui-kit** (no HTML/CSS/DOM/Node/`setTimeout`).

Official homes:

- Site: https://herdr.dev/
- App repo: https://github.com/herdrdev/herdr-app (Apache 2.0)
- Shared layouts/mods: https://herdr.dev/layouts and https://herdr.dev/mods
- Local truth for this install: `~/.config/herdr-app/AGENTS.md` + `herdr.d.ts` + `gpui-kit.d.ts`
- Agent manuals: `herdr-app --skill`, `hc --skill`

Separate product: **Herdr TUI** (older terminal multiplexer with its own server). Desktop app and TUI do not share agent sessions ([herdr.dev FAQ](https://herdr.dev/)).

Local related work (not Herdr upstream):

- Dotfiles worktree with a custom **usage** mod + `main-usage` layout: this repo (`dotfiles.feat-herdr-usage-panel`)
- Homelab docs/configs mention Herdr for nodes/SSH (`/home/xcvb/projects/homelab`), not panel APIs

---

## 2. How custom mods / panels work

### Folder shape

```
~/.config/herdr-app/mods/<name>/
  main.js     required; default-export a class extending View
  mod.json    optional placement / focus / overlay hints
  *.js, *.svg more modules and icons
```

Cited: `AGENTS.md` § Mods.

### `mod.json` schema (documented fields)

From `AGENTS.md`:

```json
{
  "place": "right" | "left" | "top" | "bottom" | "none",
  "size": 320,
  "focusable": true,
  "overlay": { "width": 280, "height": 100 }
}
```

- **`place`**: where Herdr **first docks** a newly seen mod into the shown layout. `"none"` means only where a layout (or another mod) puts it.
- After first sight, **layouts decide**. Saving reloads every copy in place.
- **`focusable: true`**: `pane.go` can move keyboard onto a shown copy; receives `"focus"` via `nextCommand()`.
- **`overlay`**: size for pointer-popup menus (e.g. custom `terminal_menu`).

Shipped Files / Changes / the local usage mod all use:

```json
{ "place": "none" }
```

(`mods/files/mod.json`, `mods/changes/mod.json`, `mods/usage/mod.json`)

`place: "right"` is the auto-dock shortcut for a brand-new mod. It is **not** how Files/Changes work. Those are layout-owned stack children with explicit show/hide.

### `main.js` API (summary)

- Import UI from `gpui-kit` / `gpui-base`; app data/commands from `herdr`.
- `export default class X extends View` with `init(props, cx)` and `render(cx)`.
- Re-render on `cx.notify()` and when live Herdr data changes.
- Timers: `cx.timer.every(ms, (cx) => …)` only (no `setTimeout`).
- Async: `cx.spawn(async (cx) => …)`. Never keep a `cx` across callbacks.
- Act: `run("command", args)`, `exec(cmd, args, { cwd, on })`, `hc(args)`, `fetch`, `readTextFile` / `writeTextFile`, `shared` / `setShared`, overlays, etc.
- Full surface: `herdr.d.ts`. Rules and example: `AGENTS.md` § A mod / The `herdr` module.

Validate:

```sh
herdr-app check ~/.config/herdr-app/mods/<name>
herdr-app status
herdr-app shot out/mod.png
```

Shipped mods/layouts are **read-only** (replaced on start). Clone before editing:

```sh
herdr-app do layout.clone '{"name":"main","as":"my-layout"}'
herdr-app do mod.clone '{"name":"tabs","as":"my-tabs"}'
```

### Right-side panels like Files / Changes

In shipped `main` (and the local clone `main-usage`), the work area is a row: terminals (`main`) + a **`panel` column** that starts **`hidden: true`**.

Inside `panel` → stack `panel-body` with children `files` and `changes`, `active: "files"`:

```json
{
  "id": "panel",
  "type": "column",
  "hidden": true,
  "size": { "px": 368 },
  "min": 280,
  "max": 900,
  "children": [
    {
      "id": "panel-body",
      "type": "stack",
      "active": "files",
      "children": [
        { "id": "files", "type": "block", "content": { "mod": "files" } },
        { "id": "changes", "type": "block", "content": { "mod": "changes" } }
      ]
    }
  ]
}
```

Cited: `layouts/main.json`, `layouts/main-usage.json`.

**Toggle pattern** (from `mods/tabs/main.js`):

1. Enabled set: `shared("workspace.panels") ?? ["files", "changes"]`
2. Show: `run("layout.select", { stack: "panel-body", child: id })` then `run("layout.show", { id: "panel" })`
3. Hide: `run("layout.hide", { id: "panel" })`
4. Per-space memory of which panel was open: tabs mod `localStorage` key `"panels"`

Welcome (`frame/welcome/main.js`) defines the pickable panel list and writes `workspace.panels`. `frame/` is rewritten every start — do not rely on editing it permanently.

**Important:** the shipped `tabs` mod **hardcodes** Files/Changes buttons:

```js
.when(enabled.includes("files"), … panelButton("files", …))
.when(enabled.includes("changes"), … panelButton("changes", …))
```

Adding a third right-stack panel requires a **cloned tabs mod** (or another chrome mod) that draws a button for the new id, plus a layout clone that adds the stack child. Putting the id only in `workspace.panels` is not enough for a tab-bar button.

Contrast: the existing **usage** mod in this worktree is a **left sidebar block** (`usage-panel` under `sidebar-body`), toggled with `layout.toggle:usage-panel` (`keys.json` `ctrl-shift-u`). Same mod API; different placement pattern than Files/Changes.

---

## 3. Registration, layout JSON, host/node navigation

### Registration checklist (right stack, Files-style)

1. Create `mods/<name>/main.js` + `mod.json` with `{ "place": "none" }`.
2. `layout.clone` the layout you use (e.g. `main` / `main-usage`).
3. Add a stack child under `panel-body`:
   `{ "id": "<name>", "type": "block", "content": { "mod": "<name>" } }`.
4. `mod.clone` `tabs` (or edit your clone) so the tab bar can open it with `layout.select` / `layout.show` / `layout.hide`.
5. Optionally append `"<name>"` to shared `"workspace.panels"` so enable/disable matches the Files/Changes convention.
6. Point the layout’s tabs block at the cloned tabs mod if you changed code.
7. `herdr-app check` the new mod; switch to the cloned layout; verify with `shot`.

Alternate (simpler, not Files-like): set `"place": "right", "size": 320` so Herdr docks it once on first discovery (`AGENTS.md`). Layout still owns later placement.

### Layout JSON structure

Tree of nodes (`AGENTS.md` § Layouts):

| `type` | Meaning |
|---|---|
| `block` | Content: `{ mod, props? }`, `{ tab: "active", pane? }`, `{ terminal }`, or `{ agent }` |
| `row` / `column` | Children side-by-side / stacked; `gap`, `divider`, `resizable` |
| `stack` | One visible child via `"active": "<id>"`; optional header |

Common node fields: `id`, `size` (`px` or `weight`), `min`/`max`, `hidden`, paint (`background`, `border`, `radius`, …), `padding`, `floating`, `window_drag`.

Click-persisted sizes / shown / stack child live in `layouts/.state/` — don’t edit by hand.

Layout commands: `layout.toggle|show|hide {id}`, `layout.resize`, `layout.select {stack, child}`, `layout.switch {name}`, `layout.clone`, `layout.reset`.

### Machines / hosts (navigation pattern)

There is **no** first-party “metrics node carousel” mod. Cross-machine patterns from the API:

- `machines()` → `{ name: string | null, layout: "loading"|"ready"|"unavailable" }[]` — `null` name is this computer (`herdr.d.ts`).
- `spaces()[i].machine` — machine that owns the space (`null` = local).
- Remote work from mods: `exec(cmd, args, { on: machine })`, `readTextFile(path, { on })`, `hc([...])` with core’s `--on`.
- CLI: `hc machine ls`; `hc exec --on <machine> …`; `hc run --on <machine> …` (`AGENTS.md` § herdr-core; `herdr-app --skill`).
- Spaces on remotes appear in the sidebar under the machine name; `space.new { machine, folder }` creates there.

Live `hc machine ls` on this install reported a connected machine named `dev` (plus local).

For a multi-node CPU/RAM panel: use `machines()` (and/or a fixed host list) in the mod, keep a selected index in `localStorage` or `shared`, poll with `exec`/`hc` and `{ on }`, draw prev/next buttons in `render`. That UI pattern is custom; Files/Changes only follow the **active space’s** machine via `space.machine` / focused pane cwd.

---

## 4. Existing metrics / usage / system-monitor mods?

| What | Exists? | Notes |
|---|---|---|
| First-party CPU/RAM/btop-style mod | **No** | Not in shipped `mods/` |
| Local **usage** mod | **Yes (custom)** | OpenCode Go + Cursor API quota gauges; left sidebar in `main-usage`; `place: none` |
| App **telemetry** | Yes | `telemetry/` — anonymized product usage for Herdr, not host metrics |
| `workspace-status` | Shipped status bar | Chrome status, not system monitor |
| Shared community mods | Possible at herdr.dev/mods | Not inventoried here; check site/GitHub topic `herdr-mod` |

Conclusion: the closest local precedent for “a panel showing meters” is `mods/usage` (API quotas). A btop-like host metrics panel would be **new**. Prefer Files/Changes registration if it should sit on the **right** with tab-bar toggles; do not confuse with the left `usage-panel` block.

---

## 5. Agent skill for herdr panel development?

Searched:

- `/home/xcvb/.agents/skills/**/SKILL.md`
- `/home/xcvb/.cursor/**/SKILL.md` (skills-cursor)
- `/home/xcvb/.harness`
- This dotfiles worktree (`home/.agents/skills`, `.pi/agent/skills`)
- Homelab `skills/`

**No dedicated `SKILL.md` for Herdr panel / mod development** was found.

What *does* exist (official, not under those skill trees):

1. **`herdr-app --skill`** — how agents drive the window; points to `AGENTS.md` for layouts/mods; includes check/shot workflow.
2. **`hc --skill`** — how agents run/coordinate terminals and remotes.
3. **`~/.config/herdr-app/AGENTS.md`** — full local guide (layouts, mod.json, API, rules). Rewritten every start; do not edit permanently.
4. Repo mirror: `defaults/AGENTS.md` in [herdrdev/herdr-app](https://github.com/herdrdev/herdr-app/blob/master/defaults/AGENTS.md).

Personal skill wraps that recipe: `home/.agents/skills/herdr/SKILL.md` (installs to `~/.agents/skills/herdr`). Metrics right panel: `mods/metrics` (+ `hosts.json` SSH extras), `tabs-metrics`, layout `main-usage`.

---

## Prior agent transcripts

Under `/home/xcvb/.cursor/projects/home-xcvb-projects/agent-transcripts`:

- Parent session `0d47240d-…`: user asked to build a right-side btop-like metrics panel for homelab nodes + laptop, with `/research`. Parent already found no herdr skill and began reading `AGENTS.md` / Files/Changes wiring / `machines()` / `/proc` sampling.
- This research subagent transcript: same investigation.

No older completed “herdr right-side panel” implementation transcript beyond the existing **usage** panel work checked into this worktree.

---

## Quick recipe: add a right-side stack panel

1. Write `mods/metrics/main.js` (View + `exec`/`machines`) and `mod.json` → `{ "place": "none" }`.
2. Clone layout; add stack child `metrics` under `panel-body`.
3. Clone `tabs`; add a `panelButton("metrics", …)` gated on `workspace.panels` (or always).
4. Optionally `setShared("workspace.panels", […, "metrics"])`.
5. `herdr-app check …/mods/metrics` and open via the new tab-bar control.

Panel API in one line: mods are GPUI-kit `View`s importing `herdr`; right Files-like panels are layout stack children + `layout.select`/`show`/`hide`, not `place: "right"` alone.
