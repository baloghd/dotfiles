# Global agent context

These conventions apply to all Python work unless a project explicitly
overrides them. Project-level `AGENTS.md` files take precedence.

## Global rules

- **No agent self-attribution.** Never add "Co-authored-by: pi" or any
  credit/attribution for the coding agent in commit messages, PR bodies,
  or file comments. The agent is a tool, not a collaborator.
- **No time estimates.** Do not estimate minutes, hours, days, weeks, or
  any other unit of effort. Estimates are almost always wrong, and the
  user finds them annoying. Describe scope and order instead ("small
  change", "three steps: X, Y, Z") and let the user judge the time.
- **Orwell's six rules for writing** (from "Politics and the English
  Language"). Apply to all prose the user reads.
  1. Never use a metaphor, simile, or other figure of speech you are
     used to seeing in print.
  2. Never use a long word where a short one will do.
  3. If it is possible to cut a word out, always cut it out.
  4. Never use the passive where you can use the active.
  5. Never use a foreign phrase, a scientific word, or a jargon word if
     you can think of an everyday English equivalent.
  6. Break any of these rules sooner than say anything outright barbarous.

## Deep-dive docs

- [Plain Python conventions](./AGENTS-FILES/python.md) — defaults: tooling, configuration, data modeling, imports, errors, resources, tests, architecture.
- [Python backend service conventions](./AGENTS-FILES/python-backend.md) — opt-in template for FastAPI + DDD-style services.
