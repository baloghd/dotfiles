# Global agent context

These conventions apply to all Python work in this environment unless a
project explicitly requires something else and you note the exception.

## Tooling

- Use `uv` for venvs, dependency management, scripts, and builds.
- Keep project metadata in `pyproject.toml`. No `setup.py`, `setup.cfg`, or
  `requirements.txt` unless the project forces it.
- Use `typer` for command-line interfaces.
- Use `ruff` for both linting and formatting. Keep the codebase warning-free.
- Use `ty` for type checking. All public functions, methods, and class
  attributes must be typed.

## Configuration

- Use `pydantic-settings` for environment-based configuration. Don't sprinkle `os.getenv` across modules.
- Keep configuration in code, environment variables, or `pyproject.toml` — never
  in hidden `.env` files committed to source.
- Do not commit `uv.lock` for libraries; commit it for applications.

## Data modeling

- Use Pydantic models for data validation and parsing.
- Prefer `enum.StrEnum` for named enumerations; `Literal[...]` for closed sets of values.
- Prefer `final` / `Final` for constants.
- Use Pydantic strict mode (`Field(strict=True)`) where coercion would mask bugs.
- Avoid mutable default arguments. Use `None` as the default and initialize
  inside the function.
- Use stdlib types over custom equivalents when they exist.

## Imports & style

- No inline imports. Every import belongs at the top of the file.
- Use absolute imports. No star imports (`from module import *`).
- Import order: stdlib, blank line, third-party, blank line, local. Sort each
  group with `ruff`/`isort`.
- Use modern Python 3.11+ syntax: `str | None` unions, `match` statements,
  `tomllib`, `asyncio.TaskGroup`, `asyncio.to_thread`, etc.
- Prefer `pathlib.Path` over `os.path` string manipulation.
- Prefer `httpx` over `requests` for HTTP clients (async support built in).
- Prefer f-strings. Avoid `.format()` and `%` formatting for new code.
- Use `functools.lru_cache` / `functools.cache` for pure helpers, not for
  anything with side effects or mutable state.

## Errors & validation

- Use `raise ValueError(...)` or a more specific exception instead of `assert`
  for runtime validation.
- Catch specific exception types; never use bare `except:` or `except Exception:`
  unless you are re-raising.
- Validate external input at the boundary and fail fast.

## Time, logging, resources

- Use timezone-aware datetimes (`datetime.now(UTC)` or `datetime.now(tz=UTC)`).
  Do not use `datetime.utcnow()` or naive datetimes for real-world times.
- Use `structlog` or the standard `logging` module. No raw `print` in
  production or library code.
- Prefer `contextlib.AsyncExitStack` or `contextlib.ExitStack` for complex
  resource management.
- Guard runnable scripts with `if __name__ == "__main__":`.
- Prefer `typer.Exit()` or `sys.exit(1)` for CLI failure; do not print an error
  and then fall through.

## Tests & functions

- Keep functions small and single-purpose. Extract helpers early. write unit tests for them! always!
- Write docstrings for public APIs (Google or NumPy style is fine).
- Write tests for edge cases, failure modes, and concurrency issues, not only
  the happy path.
- Use `pytest` for tests. Avoid `unittest` unless integrating with existing
  code.

## Architecture & quality

- If a module or function grows past the point where it's hard to read, split it. Don't refactor on a line count alone — wait until it actually hurts.
- Prefer constructor injection for collaborators. Module-level singletons are fine for stateless utilities (loggers, settings). Avoid service-locator patterns.
- Delete dead code, don't comment it out. Leave the file cleaner than you found it.
- Prefer `Protocol` for structural typing when a duck-typed boundary beats a class hierarchy.
- Write small, focused commits. One logical change per commit.
- Update tests and type stubs when changing behavior.
