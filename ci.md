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

# CI

## GitHub Actions

### Action pinning

Pin actions by SHA digest with a version comment:

```yaml
- uses: actions/checkout@<commit-sha> # vX.Y.Z
```

Tags are mutable — a digest guarantees the exact code you reviewed. Look up the
current release and its commit SHA fresh (from the action's releases page or
`gh api`); never copy them from memory, documentation, or another repository.
Renovate keeps them current afterward.

### Action sources

Judge an action by its maintainer. GitHub-owned (`actions/*`) and vendor-owned
actions (`oven-sh/setup-bun`, `docker/login-action`) are fine — you already
trust the vendor. Avoid actions from unaffiliated individuals, even popular ones
like `dtolnay/rust-toolchain`: SHA-pinning doesn't help if you trust the wrong
maintainer in the first place. Toolchains (Rust, Go, Node, Python) are
preinstalled on runners, so a setup action is often unnecessary; failing that,
prefer inline shell.

### Runner version

Specify an explicit Ubuntu version (`ubuntu-24.04`) rather than `ubuntu-latest`.
This avoids surprise breakage when GitHub rolls the latest alias forward.

### Triggers

Run on pushes to every branch, plus `pull_request` so PRs from forks still get
CI:

```yaml
on:
  push:
    branches: ["**"]
  pull_request:
```

The `branches` filter keeps tag pushes from triggering. A branch with an open PR
runs once per event; we accept the duplication so CI runs before a PR is opened
and on PRs from forks.

### Concurrency

Use this pattern to cancel superseded runs on branches while protecting main.
Including `event_name` in the group key keeps push and pull_request runs
independent so they don't cancel each other:

<!-- prettier-ignore -->
```yaml
# prettier-ignore
concurrency:
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.head_ref || github.ref_name }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

The `# prettier-ignore` comment keeps Prettier from wrapping the long group
expression.

### Build via Make

Workflows should call Make targets (`make lint`, `make coverage`), not raw tool
commands. This keeps CI configuration minimal and ensures local dev is identical
to CI.

### Permissions

Set workflow-level `permissions: contents: read` and elevate per-job only where
needed. Job-level permissions apply to every step in that job, so a job that
runs `make test` while also holding `contents: write` lets any transitive lint
or test dependency push to the repo via `GITHUB_TOKEN`. A typical Go linter
pulls in hundreds of indirect modules — that's not a defensible trust boundary.

Split by privilege: a `test` job at `contents: read` runs lint and tests; a
dependent `build` job at `contents: write` runs only compiled tools
(`go tool ko`, `docker/login-action`, etc.) whose code is pinned in `go.mod` or
by SHA.

<!-- prettier-ignore -->
```yaml
permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@... # vX.Y.Z
      - run: make lint
      - run: make test

  build:
    needs: test
    runs-on: ubuntu-24.04
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@... # vX.Y.Z
      - run: # publish images, push tags, etc.
```

The same principle applies to `id-token: write` (OIDC), `pull-requests: write`,
and any other elevation: scope it to the job that needs it, never the workflow.

### Workflow security

Audit workflows with [zizmor](https://docs.zizmor.sh/), using the pedantic
persona so it also reports hardening opportunities and not just immediately
actionable findings. It catches much of this section for you — unpinned actions,
overbroad `permissions`, and template injection among them.

Run it in CI with the
[`zizmorcore/zizmor-action`](https://github.com/zizmorcore/zizmor-action).
Pedantic holds your own workflows to the same bar: a `name` on every workflow
and job, a [`concurrency`](#concurrency) limit, and an explanatory comment on
every [`permissions`](#permissions) entry beyond the baseline `contents: read`.
The workflow below is itself clean under pedantic:

<!-- prettier-ignore -->
```yaml
name: zizmor

on:
  push:
    branches: ["**"]
  pull_request:

permissions:
  contents: read

# prettier-ignore
concurrency:
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.head_ref || github.ref_name }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

jobs:
  zizmor:
    name: zizmor
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@<commit-sha> # vX.Y.Z
        with:
          persist-credentials: false
      - uses: zizmorcore/zizmor-action@<commit-sha> # vX.Y.Z
        with:
          persona: pedantic
          advanced-security: false
```

We don't use GitHub code scanning; `advanced-security: false` skips the SARIF
upload and makes the run fail directly on findings.

## Renovate

Use [Renovate](https://docs.renovatebot.com/) rather than Dependabot. Renovate
supports grouped updates, automerge, and regex managers for non-standard
dependency sources (Dockerfile digests, action SHAs, tool versions in
Makefiles).

Place the config in `.github/renovate.json5`:

```json5
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  extends: ["config:best-practices", ":semanticCommitsDisabled"],
  platformAutomerge: true,
  packageRules: [
    {
      description: "Automerge non-major updates",
      matchUpdateTypes: ["minor", "patch", "pin", "digest"],
      automerge: true,
    },
    {
      description: "Automerge dev dependencies",
      matchDepTypes: ["devDependencies"],
      automerge: true,
    },
  ],
}
```

Key choices:

- **`:semanticCommitsDisabled`** — matches the
  [commit message convention](README.md#commit-messages) of plain imperative
  sentences.
- **`platformAutomerge`** — uses GitHub's native auto-merge, which waits for
  required checks, rather than Renovate's branch-based approach.
- **Dev dependency automerge includes majors** — dev dependencies can't break
  production, and the merge still waits for required checks.

For Go projects, add `postUpdateOptions: ["gomodTidy"]` so dep updates
regenerate `go.sum`; otherwise tool bumps leave it missing `h1:` hashes for new
transitive deps. Casing matters: `goModTidy` is silently ignored.
