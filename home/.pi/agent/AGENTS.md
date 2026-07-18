# Global agent context

These conventions apply to all Python work unless a project explicitly
overrides them. Project-level `AGENTS.md` files take precedence.

## Global rules

- **No agent self-attribution.** Never add "Co-authored-by: pi" or any
  credit/attribution for the coding agent in commit messages, PR bodies,
  or file comments. The agent is a tool, not a collaborator.

## Deep-dive docs

- [Plain Python conventions](./AGENTS-FILES/python.md) — defaults: tooling, configuration, data modeling, imports, errors, resources, tests, architecture.
- [Python backend service conventions](./AGENTS-FILES/python-backend.md) — opt-in template for FastAPI + DDD-style services.
