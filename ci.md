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

### Workflow dependency locks

Use readable full-version tags for actions and commit the generated
`.github/workflows/actions.lock`:

```yaml
- uses: actions/checkout@vX.Y.Z
```

The
[workflow dependency lockfile](https://docs.github.com/en/actions/concepts/security/workflow-dependency-lockfiles)
records the verified commit and repository identity for each direct and
transitive action dependency. Look up current releases fresh; never copy
versions from memory or examples. Review changes to locked commits, repository
identities, and composite-action dependencies as executable code changes.

Install the pinned `github/gh-actions-lock` extension through
`make actions-lock-install`. Run `make actions-lock` after adding or editing
workflows; never edit the lockfile by hand. Onboard every workflow, including
verification workflows and workflows without action dependencies.

Provide these Make targets in every participating repository:

| Target                      | Command                                                            |
| --------------------------- | ------------------------------------------------------------------ |
| `actions-lock-install`      | `gh extension install github/gh-actions-lock --pin vX.Y.Z --force` |
| `actions-lock`              | `gh actions-lock --no-interactive`                                 |
| `actions-lock-verify-local` | `gh actions-lock --verify-local`                                   |
| `actions-lock-verify`       | `gh actions-lock --verify`                                         |

Include offline coverage verification in `make lint`. Run online provenance
verification in a separate read-only CI job named `actions-lock`, passing
`GH_TOKEN: ${{ github.token }}` only to the step that needs it. Offline checks
do not establish provenance. Require the online check after it has been
published and its exact emitted name has been confirmed.

Lockfiles do not cover external reusable workflow calls or container images.
Keep full commit SHAs with version comments on external `jobs.<job_id>.uses`
references, and digest pins on containers. Preserve same-repository workflow
references. A called reusable workflow's actions must be locked in its source
repository.

Inspect local actions before converting `./path` to `$/path`. `./path` runs from
the checked-out workspace, which can intentionally contain generated or modified
files; `$/path` resolves from the workflow's source commit. Do not change that
behavior just to satisfy the lock tool. Document and review any necessary
exception for a workspace action with remote dependencies.

After publishing and verifying coverage in every targeted workflow and called
workflow, enable the **Require lockfile** execution policy. Start in Evaluate
mode where available, scoped to participating repositories, then activate it
after examining actual runs. It blocks uncovered workflows even when they
contain no actions. Exclude forks and archived repositories from the rollout. If
the account cannot use the policy, record the limitation and retain the required
online verification check. See GitHub's
[enforcement guide](https://docs.github.com/en/actions/how-tos/administer/enforce-workflow-lockfiles).

### Action sources

Judge an action by its maintainer. GitHub-owned (`actions/*`) and vendor-owned
actions (`oven-sh/setup-bun`, `docker/login-action`) are fine — you already
trust the vendor. Avoid actions from unaffiliated individuals, even popular ones
like `dtolnay/rust-toolchain`: SHA-pinning doesn't help if you trust the wrong
maintainer in the first place. Toolchains (Rust, Go, Node, Python) are
preinstalled on runners, so a setup action is often unnecessary; failing that,
prefer inline shell.

### Runner version

Specify an explicit Ubuntu version (`ubuntu-26.04`) rather than `ubuntu-latest`.
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
change after a docs-only follow-up. Default-branch pushes compare the head SHA
of the workflow's latest successful push run on that branch, so changes from a
failed or cancelled run stay selected until a later run passes. Find it through
the Actions API (`gh api repos/$GITHUB_REPOSITORY/actions/workflows/<file>/runs`
with `branch`, `event=push`, `status=success`, and `per_page=1`) from a job with
`actions: read`, and give only `gh` the token, not the selector's other
commands. A failed lookup fails the run. No successful run, a malformed or
missing commit, or a base that is not an ancestor of the pushed commit runs the
complete checks, as do unknown paths.

Do not require branches to be up to date before merging: each merge would
invalidate every open branch's checks. Pair that with Renovate's
`rebaseWhen: "conflicted"`, since automerge otherwise rebases every update
branch onto each new default-branch commit.

An expensive default-branch job may be skipped when a branch push run of the
same tree (`head_commit.tree_id`) passed every job on GitHub-hosted runners
recently; runner images change, so only a recent result stands in. A job that
needs a skipped job is skipped too, and so are its indirect dependents unless
each overrides the default `success()` with `!cancelled()` and explicit result
checks (actions/runner#2205).

Give every job `timeout-minutes` so stuck work cannot run for GitHub's six-hour
default.

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
the workflow lockfile.

<!-- prettier-ignore -->
```yaml
permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-26.04
    steps:
      - uses: actions/checkout@vX.Y.Z
      - run: make lint
      - run: make test

  build:
    needs: test
    runs-on: ubuntu-26.04
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@vX.Y.Z
      - run: # publish images, push tags, etc.
```

Publish the commit that passed the prerequisite checks. On tag-triggered
releases, test the tag's commit; on dependent workflows, check out the tested
run's head SHA. Do not resolve a moving default branch after tests finish.

The same principle applies to `id-token: write` (OIDC), `pull-requests: write`,
and any other elevation: scope it to the job that needs it, never the workflow.

### Workflow security

Audit workflows with a lockfile-aware version of
[zizmor](https://docs.zizmor.sh/), using the pedantic persona so it also reports
hardening opportunities and not just immediately actionable findings. It catches
much of this section for you — unpinned actions, overbroad `permissions`, and
template injection among them.

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
    runs-on: ubuntu-26.04
    steps:
      - uses: actions/checkout@vX.Y.Z
        with:
          persist-credentials: false
      - uses: zizmorcore/zizmor-action@vX.Y.Z
        with:
          persona: pedantic
          advanced-security: false
```

We don't use GitHub code scanning; `advanced-security: false` skips the SARIF
upload and makes the run fail directly on findings.

### Repository settings

Protect the default branch before enabling auto-merge. Require meaningful lint,
test, build, coverage, workflow-security, and lockfile checks where applicable.
Bind required checks to GitHub Actions and use the exact names emitted by
successful workflow runs, including matrix suffixes. A conditionally skipped job
can satisfy a required check; ensure path selection and aggregate jobs still
fail when required work fails or is unexpectedly skipped.

Disable up-to-date branch enforcement by default. Allow administrator bypass;
give Renovate no bypass. Block default-branch deletion and force pushes. Keep
workflow tokens read-only by default and disable approval of pull requests by
workflow tokens. Elevate individual jobs only for a documented need.

Inspect classic branch protection, effective rulesets, and inherited Actions
policies before changing settings. Update the existing protection layer and
preserve additional restrictions and intentional exceptions. Publish new
workflows and confirm their check names before requiring them or activating
execution policies. Read settings back after each change. Record unavailable
features and publication-dependent changes separately from completed rollout.

## Renovate

Use [Renovate](https://docs.renovatebot.com/) rather than Dependabot. Renovate
supports grouped updates, automerge, and regex managers for non-standard
dependency sources (Dockerfile digests, action SHAs, tool versions in
Makefiles).

Its
[GitHub Actions manager](https://github.com/renovatebot/renovate/blob/main/lib/modules/manager/github-actions/readme.md#github-actions-lockfile-actionslock)
regenerates existing workflow lockfiles in the same branch as action updates. It
does not onboard new workflows. Keep digest pinning enabled for dependencies
outside lockfile coverage, and review the workflow and lockfile changes
together. The base preset pins the lock tool used by Renovate and updates the
Makefile installation pin through a custom manager.

Use the shared presets from this repository. Place the config in
`.github/renovate.json5`:

```json5
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  extends: ["github>shields/right-answers//renovate/base.json5"],
}
```

| Preset                                  | Policy                                                                                                                                      |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [base.json5](renovate/base.json5)       | Best practices, plain commit messages, platform automerge, rebasing only on conflict, and three-day cooldowns for npm, PyPI, and crates.io. |
| [go.json5](renovate/go.json5)           | Run `gomodTidy` after dependency updates to regenerate `go.sum`, including hashes for new transitive dependencies.                          |
| [paid-ci.json5](renovate/paid-ci.json5) | Batch non-major npm and GitHub Actions updates separately and allow a daily midnight–4 a.m. window in Los Angeles time.                     |

Optional presets add to the base; they do not include it. For a Go repository
with paid CI:

```json5
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  extends: [
    "github>shields/right-answers//renovate/base.json5",
    "github>shields/right-answers//renovate/go.json5",
    "github>shields/right-answers//renovate/paid-ci.json5",
  ],
}
```

These references follow this repository's default branch. A merged preset change
applies to consumers on subsequent Renovate runs without a consumer PR. Publish
new presets before migrating other repositories to reference them.

Keep custom managers, version restrictions, project-specific exceptions, and
additional ecosystem groups in the consuming repository. Repository settings
override preset settings, except for mergeable options such as `packageRules`,
which append to the inherited rules. Later matching package rules take
precedence. See Renovate's
[configuration precedence](https://docs.renovatebot.com/config-overview/#config-precedence).

### Automerge

The base preset preserves these choices:

- **`:semanticCommitsDisabled`** — matches the
  [commit message convention](README.md#commit-messages) of plain imperative
  sentences.
- **`rebaseWhen: "conflicted"`** — rebases an update branch only when it
  conflicts, so merges to the default branch do not rerun CI on every open
  update.
- **`platformAutomerge`** — uses GitHub's native auto-merge, which waits for
  required checks, rather than Renovate's branch-based approach.
- **Non-major automerge** — minor, patch, pin, and digest updates may automerge.
- **Dev dependency automerge includes majors** — updates matching
  `devDependencies` may automerge after required checks pass. Cooldowns still
  apply to eligible update types.

### Cooldowns

The base inherits `security:minimumReleaseAgeNpm` through
`config:best-practices` and adds `security:minimumReleaseAgePypi` and
`security:minimumReleaseAgeCrate`. These
[upstream presets](https://docs.renovatebot.com/presets-security/) require a
minimum release age of three days and filter out pending releases before
creating update branches. This applies to regular major, minor, and patch
updates of both production and development dependencies. Renovate's default
release-age buffer also applies.

Preserve the upstream timestamp requirement and exceptions for update types that
cannot enforce release age, including pinning, replacements, and lockfile
maintenance. Vulnerability-alert fixes bypass the cooldown by default. No
blanket cooldown applies to other datasources; requiring timestamps from a
source that does not provide them can block updates indefinitely.

Renovate's cooldown does not cover every newly resolved transitive dependency or
lockfile-maintenance update. Package-manager cooldown settings provide
additional coverage and must be configured separately. See Renovate's
[minimum release age documentation](https://docs.renovatebot.com/key-concepts/minimum-release-age/).

### Paid CI

Cooldowns measure the age of each release. The optional paid-CI schedule
controls when eligible updates run; it does not schedule a bot run or delay
updates until a project stops publishing releases.

Add separate groups for the repository's other ecosystems. Keep JavaScript
updates separate from native dependencies so path selection can skip macOS.
`updateNotScheduled: false` also delays routine updates to existing branches;
the preset exempts vulnerability alerts, which retain their separate,
unscheduled branches.

### Validation

Run `make install`, then `make lint`. All project tools run under Bun. Lint runs
`renovate-config-validator --strict --no-global` against every checked-out
preset and this repository's Renovate configuration. Git hooks and CI run the
same checks.

Validation sets `RENOVATE_X_IGNORE_RE2=true` to use JavaScript's regex engine.
These presets define no custom regex patterns; validation does not guarantee RE2
compatibility for patterns added later. Dependency lifecycle scripts are not
trusted, so installation does not build the optional native RE2 binding.

Validating the local files checks proposed policy before publication. It does
not prove that a remote preset reference resolves. After publishing, verify
successful preset resolution on the next Renovate run before migrating other
repositories.
