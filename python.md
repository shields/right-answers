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
