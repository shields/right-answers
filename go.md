# Go

## Tooling

Use the latest stable version of Go. Take advantage of
[`go tool`](https://go.dev/doc/modules/managing-tools) for managing
project-specific tool dependencies rather than installing tools globally.

## Linting and formatting

Use [gofumpt](https://github.com/mvdan/gofumpt) for formatting (a stricter
superset of `gofmt`).

Use [golangci-lint v2](https://golangci-lint.run/) for linting. A shared
[`.golangci.yml`](.golangci.yml) is provided in this repository. The
configuration enables all linters by default with a curated set of exclusions.

## Error handling

Always wrap errors with context using `fmt.Errorf("context: %w", err)` to
preserve the error chain. Use `errors.Is` and `errors.As` for checking
errors—never compare with `==` except against `nil`.

Define sentinel errors at the package level for errors that callers need to
check:

```go
var ErrNotFound = errors.New("not found")
```

Never discard errors silently. If an error is truly ignorable, assign to `_`
with a comment explaining why.

## Logging

Use [`log/slog`](https://pkg.go.dev/log/slog) from the standard library for
structured logging. Do not use third-party logging libraries (logrus, zap,
zerolog) without a specific, documented reason.

Always use structured fields rather than string formatting:

```go
slog.Info("request handled",
    "method", r.Method,
    "path", r.URL.Path,
    "duration", elapsed,
)
```

Use `slog.With` to create loggers with common fields for a request or component
scope. Prefer `slog.LevelInfo` as the default level.

## Makefile example

```makefile
.PHONY: lint fmt test

lint:
	go tool golangci-lint run

fmt:
	go tool gofumpt -w .

test:
	go test ./...
```
