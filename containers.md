# Containers

## Base images

Use [Distroless](https://github.com/GoogleContainerTools/distroless) base images
by default. Distroless images contain only the application and its runtime
dependencies—no shell, no package manager, and a minimal attack surface.

Choose the appropriate variant:

- **`gcr.io/distroless/static-debian13`** for statically linked binaries (Go
  with `CGO_ENABLED=0`).
- **`gcr.io/distroless/base-debian13`** for dynamically linked binaries that
  need glibc.
- **`gcr.io/distroless/cc-debian13`** when libstdc++ is also required.

Use the `:nonroot` tag to run as a non-root user by default.

Always reference base images by SHA digest rather than tag alone. Tags are
mutable—a digest guarantees the exact image you tested against:

```dockerfile
FROM gcr.io/distroless/static-debian13:nonroot@sha256:<digest>
```

## Building Go containers

Use [ko](https://ko.build/) for building Go container images. ko builds directly
from `go build`, produces SBOMs, and requires no Dockerfile. It defaults to a
Distroless base image when `CGO_ENABLED=0`, which is the preferred
configuration.

To explicitly set the base image, add a `.ko.yaml` at the project root:

```yaml
defaultBaseImage: gcr.io/distroless/static-debian13:nonroot
```

## Makefile targets

```makefile
.PHONY: image

image:
	ko build ./cmd/server
```
