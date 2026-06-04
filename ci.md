# CI

## GitHub Actions

### Action pinning

Pin actions by SHA digest with a version comment:

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

Tags are mutable — a digest guarantees the exact code you reviewed. Renovate
updates these automatically.

### Action sources

Prefer GitHub-owned actions (`actions/*`) or inline shell over third-party
actions maintained by individuals, even popular ones like
`dtolnay/rust-toolchain` or `Swatinem/rust-cache`. SHA-pinning protects against
tag mutation but doesn't help if you trust the wrong maintainer in the first
place. Toolchains (Rust, Go, Node, Python) are preinstalled on the runner; reach
for a third-party action only when there's no reasonable alternative.

### Runner version

Specify an explicit Ubuntu version (`ubuntu-24.04`) rather than `ubuntu-latest`.
This avoids surprise breakage when GitHub rolls the latest alias forward.

### Concurrency

Use this pattern to cancel superseded runs on branches while protecting main.
Including `event_name` in the group key keeps push and pull_request runs
independent so they don't cancel each other:

<!-- prettier-ignore -->
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.head_ref || github.ref_name }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

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
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.head_ref || github.ref_name }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

jobs:
  zizmor:
    name: zizmor
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      actions: read # only needed for SARIF upload on private repos
      security-events: write # upload findings to code scanning
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          persist-credentials: false
      - uses: zizmorcore/zizmor-action@5f14fd08f7cf1cb1609c1e344975f152c7ee938d # v0.5.6
        with:
          persona: pedantic
```

The action uploads findings to code scanning by default; set
`advanced-security: false` on repositories without GitHub Advanced Security.

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

For Go projects, add `postUpdateOptions: ["gomodTidy"]` so dep updates
regenerate `go.sum`; otherwise tool bumps leave it missing `h1:` hashes for new
transitive deps. Casing matters: `goModTidy` is silently ignored.
