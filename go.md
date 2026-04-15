# Go

## Tooling

Use the latest stable version of Go. Take advantage of
[`go tool`](https://go.dev/doc/modules/managing-tools) for managing
project-specific tool dependencies rather than installing tools globally.

## CI

Runners already include Go, but
[`actions/setup-go`](https://github.com/actions/setup-go) adds caching
for downloaded modules and compiled packages. Use `go-version-file`
rather than hardcoding a version:

```yaml
- uses: actions/setup-go
  with:
    go-version-file: go.mod
```

## Linting and formatting

Use [gofumpt](https://github.com/mvdan/gofumpt) for formatting (a stricter
superset of `gofmt`).

Use [golangci-lint v2](https://golangci-lint.run/) for linting. A shared
[`.golangci.yml`](.golangci.yml) is provided in this repository. The
configuration enables all linters by default with a curated set of exclusions.

## Test coverage

`go tool cover -func` undercounts: it parses the AST for `*ast.FuncDecl`
nodes, so statements inside package-level function literals
(`var x = func() { ... }()`) are excluded from the total. Parse the
profile directly instead:

```makefile
@LC_ALL=C awk 'NR>1{t+=$$2;if($$3>0)c+=$$2} \
  END{printf "Coverage: %.1f%%\n",(t>0?100*c/t:0); \
  if(c!=t){print "FAIL: coverage is not 100.0%";exit 1}}' $(COVERAGE_FILE)
```

`LC_ALL=C` prevents locale-dependent decimal separators. `c!=t` compares
integer statement counts rather than the formatted string, which avoids
`printf` rounding 99.95% up to `100.0%`.

To make init-time function literals coverable, extract them into named
functions with injectable dependencies so tests can mock the error paths.

## Logging

Use [`log/slog`](https://pkg.go.dev/log/slog) from the standard library for
structured logging. Do not use third-party logging libraries (logrus, zap,
zerolog).
