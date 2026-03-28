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

Use [ty](https://docs.astral.sh/ty/) for type checking.

## Error handling

Define custom exceptions inheriting from a project-level base exception, which
itself inherits from `Exception` (not `BaseException`).

## Logging

Use [structlog](https://www.structlog.org/) for structured logging in services.
For scripts and CLI tools, the standard library `logging` module is sufficient.
