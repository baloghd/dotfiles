# Global agent context

These conventions apply to all Python work in this environment unless a
project explicitly requires something else and you note the exception.

## Python conventions

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
