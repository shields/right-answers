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

For private repositories whose contributions come from branches in the same
repository, run once per branch push:

```yaml
on:
  push:
    branches: ["**"]
```

A pull request displays the checks attached to its branch commit, so opening a
PR is unnecessary to get CI. These builds test the branch head, not GitHub's
synthetic merge commit. The `branches` filter excludes tags.

Repositories accepting forks need `pull_request`, because a push in a fork does
not trigger the upstream workflow. Use pushes to the default branch plus
`pull_request` when merge-result testing matters. If every branch needs pre-PR
checks as well, retain both triggers and account for their duplicate builds. Do
not add a skipped same-name PR job to deduplicate checks: its successful skip
can obscure the branch build's result.

Path selection on feature branches must cover the full diff from the merge base
with the default branch. Comparing only the latest push can skip an earlier code
change after a docs-only follow-up. Default-branch pushes compare the previous
commit. Missing bases and unknown paths run the complete checks.

### Concurrency

Cancel superseded branch runs while protecting main:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

For workflows with both push and pull-request triggers, add `github.event_name`
to the group key so the events cannot cancel one another. Use `github.ref` for
PRs: its `refs/pull/N/merge` value is unique even when forks share a branch
name.

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

```yaml
name: zizmor

on:
  push:
    branches: ["**"]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.ref }}
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

For repositories with paid CI, batch compatible non-major updates by ecosystem
and allow a four-hour daily window. For example:

```json5
{
  timezone: "America/Los_Angeles",
  schedule: ["* 0-3 * * *"],
  updateNotScheduled: false,
  vulnerabilityAlerts: { updateNotScheduled: true },
  packageRules: [
    {
      matchDatasources: ["npm"],
      matchUpdateTypes: ["minor", "patch", "pin", "digest"],
      groupName: "JavaScript non-major dependencies",
    },
    {
      matchManagers: ["github-actions"],
      matchUpdateTypes: ["minor", "patch", "pin", "digest"],
      groupName: "GitHub Actions non-major dependencies",
    },
  ],
}
```

Add separate groups for the repository's other ecosystems. Keep JavaScript
updates separate from native dependencies so path selection can skip macOS.
`updateNotScheduled: false` also delays routine updates to existing branches;
Renovate's vulnerability alerts retain their separate, unscheduled branches. The
window permits updates when Renovate visits; it does not schedule a bot run.

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
