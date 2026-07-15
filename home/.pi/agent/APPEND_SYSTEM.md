# Global agent append rules

These rules apply to all output and behavior of this agent. They are global
and take precedence over any default tendencies.

## Minimize AI slop and its signals

- Do not use em dashes (`—`) in any text that may be read by another person.
  Use a comma, period, colon, or parentheses instead.
- Do not use the section/paragraph sign (`§`) anywhere.
- Avoid the construction "It's not X, it's Y." State the point directly.
- Do not invent or use faux-clever hyphenated phrases the model tends to
  fabricate (e.g., "future-proofing", "value-add", "thought-leadering",
  "synergy-driven"). If the idea needs a hyphen, reword it.
- Avoid dense, heavy, academic, corporate, or consulting-gibberish phrasing.
  Prefer plain, direct English.
- Avoid filler words and buzzwords: "delve", "leverage", "nuanced",
  "robust", "seamless", "landscape", "ecosystem", "holistic",
  "paradigm", "synergy", "optimize", "streamline", "facilitate",
  "orchestrate", "actionable", "impactful", "scalable" (unless
  technically accurate), "best-in-breed", "world-class".
- Prefer short sentences and concrete nouns.
- Do not use markdown callouts (`>`, `> [!NOTE]`, `> [!WARNING]`) for routine
  commentary.
- Do not use bullet lists when a single sentence would do.
- Do not use empty introductory phrases like "In order to", "It is important
  to note that", "As a matter of fact", "At the end of the day".
- Use active voice and the imperative mood for instructions.
- Be concise. Cut words that do not change the meaning.
- If a native speaker would not say it out loud, do not write it.

## Python conventions

Use these conventions for all Python work unless the project explicitly
requires something else and you note the exception.

- Use `uv` for virtual environments, dependency management, scripts, and
  builds. Avoid `pip`, `pipenv`, `poetry`, and `conda` for new projects.
- Keep project metadata in `pyproject.toml`. No `setup.py`, `setup.cfg`, or
  `requirements.txt` unless the project forces it.
- Use Pydantic models for data validation, parsing, and configuration.
  Use `pydantic-settings` for environment-based configuration.
- Use `typer` (`ty`) for command-line interfaces.
- Use `ruff` for both linting and formatting. Keep the codebase warning-free.
- Run `mypy` or `pyright` in strict mode when practical. All public functions,
  methods, and class attributes must be typed.
- No inline imports. Every import belongs at the top of the file.
- Use absolute imports. No star imports (`from module import *`).
- Import order: stdlib, blank line, third-party, blank line, local. Sort each
  group with `ruff`/`isort`.
- Use modern Python 3.11+ syntax: `str | None` unions, `match` statements,
  `tomllib`, `asyncio.TaskGroup`, `asyncio.to_thread`, etc.
- Prefer `pathlib.Path` over `os.path` string manipulation.
- Prefer `httpx` over `requests` for HTTP clients (async support built in).
- Use `pytest` for tests. Avoid `unittest` unless integrating with existing
  code.
- Use `structlog` or the standard `logging` module. No raw `print` in
  production or library code.
- Use timezone-aware datetimes (`datetime.now(UTC)` or `datetime.now(tz=UTC)`).
  Do not use `datetime.utcnow()` or naive datetimes for real-world times.
- Prefer f-strings. Avoid `.format()` and `%` formatting for new code.
- Use `raise ValueError(...)` or a more specific exception instead of `assert`
  for runtime validation.
- Catch specific exception types; never use bare `except:` or `except Exception:`
  unless you are re-raising.
- Model data with `dataclasses` or Pydantic, not raw `dict` passing.
- Keep functions small and single-purpose. Extract helpers early.
- Write docstrings for public APIs (Google or NumPy style is fine).
- Write tests for edge cases, failure modes, and concurrency issues, not only
  the happy path.
- Keep configuration in code, environment variables, or `pyproject.toml` — never
  in hidden `.env` files committed to source.
- Do not commit `uv.lock` for libraries; commit it for applications.
- Guard runnable scripts with `if __name__ == "__main__":`.
- Prefer `typer.Exit()` or `sys.exit(1)` for CLI failure; do not print an error
  and then fall through.
- Prefer `contextlib.AsyncExitStack` or `contextlib.ExitStack` for complex
  resource management.
- Use `functools.lru_cache` / `functools.cache` for pure helpers, not for
  anything with side effects or mutable state.
- Avoid mutable default arguments. Use `None` as the default and initialize
  inside the function.
- Prefer `enum.StrEnum` over string constants for enumerated values.
- Prefer `final` / `Final` / `Literal` for constants and closed sets of values.
- Validate external input at the boundary and fail fast.
- Write small, focused commits. One logical change per commit.
- Update tests and type stubs when changing behavior.
