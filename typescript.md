# TypeScript/JavaScript

## Tooling

Use [Bun](https://bun.sh/) as the package manager and test runner. Use
`bun install` and `bun.lock` for dependency management. Do not use npm, yarn,
or pnpm.

All projects must use ESM (`"type": "module"` in `package.json`).

## TypeScript configuration

Use TypeScript in type-checking-only mode (`noEmit: true`). Enable
`erasableSyntaxOnly` for compatibility with Node.js native type stripping.

A shared [`tsconfig.json`](tsconfig.json) is provided in this repository. Enable
all strict checks and then some. Key flags beyond `strict`:

- **`noUncheckedIndexedAccess`** — index signatures return `T | undefined`,
  catching a common class of runtime errors.
- **`exactOptionalPropertyTypes`** — distinguishes between a missing property
  and one explicitly set to `undefined`.
- **`erasableSyntaxOnly`** — ensures the code runs under Node.js type
  stripping without a build step.

## Linting

Use [ESLint](https://eslint.org/) with
[typescript-eslint](https://typescript-eslint.io/) and
[eslint-plugin-unicorn](https://github.com/sindresorhus/eslint-plugin-unicorn).

Enable the strictest type-checked rule sets:

- `tseslint.configs.strictTypeChecked`
- `tseslint.configs.stylisticTypeChecked`
- `unicorn.configs.unopinionated`

Require `eqeqeq`. A shared [`eslint.config.ts`](eslint.config.ts) is provided
in this repository. It includes
[eslint-config-prettier](https://github.com/prettier/eslint-config-prettier) as
the final config entry to disable rules that conflict with Prettier.

## Formatting

Use [Prettier](https://prettier.io/) for code formatting. Prettier's defaults
are intentionally adopted with minimal overrides—this aligns with the
"opinionated defaults" philosophy used across all language guides.

## Testing

Use `bun test` with 100% coverage thresholds. A shared
[`bunfig.toml`](bunfig.toml) is provided in this repository.

## Error handling

Prefer typed error classes extending `Error` with a `cause` property for
wrapping:

```ts
class AppError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "AppError";
  }
}

throw new AppError("failed to process", { cause: err });
```

Use `unknown` in catch clauses (enforced by `strict`) and narrow before
accessing properties. Do not use exceptions for control flow.

## Logging

Use [pino](https://getpino.io/) for structured logging:

```ts
import pino from "pino";

const log = pino();
log.info({ method: req.method, path: req.url }, "request handled");
```

## Makefile example

```makefile
.PHONY: lint fmt check test

lint:
	bun run lint

fmt:
	bunx prettier --write .

check:
	tsc

test:
	bun test --coverage
```
