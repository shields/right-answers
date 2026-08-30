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

# Go

## Tooling

Use [`go tool`](https://go.dev/doc/modules/managing-tools) to manage
project-specific tool dependencies rather than installing tools globally.

## CI

Runners already include Go, but
[`actions/setup-go`](https://github.com/actions/setup-go) adds caching for
downloaded modules and compiled packages. Use `go-version-file` rather than
hardcoding a version, and pin the action per
[Action pinning](ci.md#action-pinning):

```yaml
- uses: actions/setup-go@<commit-sha> # vX.Y.Z
  with:
    go-version-file: go.mod
```

## Linting and formatting

Use [gofumpt](https://github.com/mvdan/gofumpt) for formatting (a stricter
superset of `gofmt`).

Use [golangci-lint v2](https://golangci-lint.run/) for linting. A shared
[`.golangci.yml`](.golangci.yml) is provided in this repository. The
configuration enables all linters by default with a curated set of exclusions.

Test files are exempt from linters whose output is mostly noise in tests:

- `goconst` via the dedicated `goconst.ignore-tests: true` setting (added in
  golangci-lint v2.12.0) — keeps test fixtures like repeated `"main.go"` from
  flagging.
- `errcheck`, `err113`, and `gosec` via a `_test\.go$` path rule under
  `linters.exclusions.rules`.

## Test coverage

`go tool cover -func` undercounts coverage. It only counts top-level function
declarations (`*ast.FuncDecl`), so statements inside package-level function
literals (`var x = func() { ... }()`) are excluded. Parse the profile directly
instead:

```makefile
@LC_ALL=C awk 'NR>1{t+=$$2;if($$3>0)c+=$$2} \
  END{printf "Coverage: %.1f%%\n",(t>0?100*c/t:0); \
  if(c!=t){print "FAIL: coverage is not 100.0%";exit 1}}' $(COVERAGE_FILE)
```

`LC_ALL=C` prevents locale-dependent decimal separators. `c!=t` compares integer
statement counts rather than the formatted string, which avoids `printf`
rounding 99.95% up to `100.0%`.

To make init-time function literals coverable, extract them into named functions
with injectable dependencies so tests can mock the error paths.

## JSON

Use [`encoding/json/v2`](https://pkg.go.dev/encoding/json/v2) instead of
`encoding/json`, plus
[`encoding/json/jsontext`](https://pkg.go.dev/encoding/json/jsontext) for
token-level work. It has been generally available since Go 1.27; do not set
`GOEXPERIMENT=jsonv2` or add build tags.

The API changed before release, so knowledge of the experimental package may be
stale:

- The tag option that flattens a field into its parent is `embed`, not `inline`.
  Unrecognized tag options are ignored without error, so `inline` quietly
  produces a nested object.
- The `unknown` and `format` tag options are gone; `RejectUnknownMembers` is the
  only control over unknown members.

Defaults that differ from v1:

- Field names match case-sensitively.
- `omitempty` omits fields that encode as an empty JSON value, not Go zero
  values; use `omitzero` for numbers, booleans, and pointers.
- Nil slices and maps marshal as `[]` and `{}`, not `null`.
- Map keys are not sorted; pass `Deterministic(true)` when output must be
  stable.
- `time.Duration` has no default representation and fails to marshal.

The [Migrating to v2](https://pkg.go.dev/encoding/json#hdr-Migrating_to_v2)
section of the `encoding/json` documentation lists every difference and the
option that restores each v1 behavior.

## Logging

Use [`log/slog`](https://pkg.go.dev/log/slog) from the standard library for
structured logging. Do not use third-party logging libraries (logrus, zap,
zerolog).
