# CI

## GitHub Actions

### Action pinning

Pin actions by SHA digest with a version comment:

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

Tags are mutable—a digest guarantees the exact code you reviewed. Renovate
updates these automatically.

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
