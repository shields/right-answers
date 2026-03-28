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

## Logging

Use [`log/slog`](https://pkg.go.dev/log/slog) from the standard library for
structured logging. Do not use third-party logging libraries (logrus, zap,
zerolog).
