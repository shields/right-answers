# Python

## Tooling

Use [uv](https://docs.astral.sh/uv/) for all Python project and package
management. Do not use pip, pip-tools, or poetry.

Target **Python 3.14** whenever possible.

## Linting and formatting

Use [Ruff](https://docs.astral.sh/ruff/) for both linting and formatting. A
shared [`.ruff.toml`](.ruff.toml) is provided in this repository. The
configuration enables all rules (`ALL`) with a targeted set of exclusions for
rules that are overly noisy or conflict with our style.

Use [ty](https://docs.astral.sh/ty/) for type checking. All code must include
type annotations. Use modern built-in generics (`list`, `dict`, `tuple`, `set`)
rather than their `typing` module equivalents.

## Error handling

Define custom exceptions inheriting from a project-level base exception, which
itself inherits from `Exception` (not `BaseException`). Use `raise ... from err`
to chain exceptions and preserve tracebacks:

```python
raise AppError("failed to process") from err
```

Catch specific exceptions—never use bare `except:` or broad
`except Exception:` without re-raising. Use context managers (`with`) for
resource cleanup rather than `try`/`finally`.

## Logging

Use [structlog](https://www.structlog.org/) for structured logging in services.
For scripts and CLI tools, the standard library `logging` module is sufficient.

Use `logging.getLogger(__name__)` per module. Configure structlog to output
JSON in production and human-readable output in development:

```python
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer(),
    ],
)

log = structlog.get_logger()
```

## Makefile example

```makefile
.PHONY: lint fmt typecheck test

lint:
	uv run ruff check .

fmt:
	uv run ruff format .

typecheck:
	uv run ty check .

test:
	uv run pytest
```
