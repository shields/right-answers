<!--
Copyright © 2026 Michael Shields

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

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

## Testing

Use [pytest](https://docs.pytest.org/) for tests. Write tests as plain functions
with bare `assert` statements rather than `unittest.TestCase` subclasses, and
use fixtures rather than `setUp`/`tearDown`.

## Logging

Use [structlog](https://www.structlog.org/) for structured logging in services.
For scripts and CLI tools, the standard library `logging` module is sufficient.
