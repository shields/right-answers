# TypeScript/JavaScript

## Tooling

Use [Bun](https://bun.sh/) as the package manager and test runner. Use
`bun install` and `bun.lock` for dependency management. Do not use npm, yarn, or
pnpm.

## TypeScript configuration

Use TypeScript in type-checking-only mode (`noEmit: true`).

A shared [`tsconfig.json`](tsconfig.json) is provided in this repository. Enable
all strict checks and then some. Key flags beyond `strict`:

- **`noUncheckedIndexedAccess`** — index signatures return `T | undefined`,
  catching a common class of runtime errors.
- **`exactOptionalPropertyTypes`** — distinguishes between a missing property
  and one explicitly set to `undefined`.
- **`erasableSyntaxOnly`** — ensures the code runs under Node.js type stripping
  without a build step.

## Linting

Use [ESLint](https://eslint.org/) with
[typescript-eslint](https://typescript-eslint.io/) and
[eslint-plugin-unicorn](https://github.com/sindresorhus/eslint-plugin-unicorn).

Enable the strictest type-checked rule sets:

- `tseslint.configs.strictTypeChecked`
- `tseslint.configs.stylisticTypeChecked`
- `unicorn.configs.unopinionated`

Require `eqeqeq`. A shared [`eslint.config.ts`](eslint.config.ts) is provided in
this repository. It includes
[eslint-config-prettier](https://github.com/prettier/eslint-config-prettier) as
the final config entry to disable rules that conflict with Prettier.

## Formatting

Use [Prettier](https://prettier.io/) for code formatting. Prettier's defaults
are intentionally adopted with minimal overrides.

## Testing

Use `bun test` with 100% coverage thresholds. A shared
[`bunfig.toml`](bunfig.toml) is provided in this repository.

## Logging

Use [pino](https://getpino.io/) for structured logging:

```ts
import pino from "pino";

const log = pino();
log.info({ method: req.method, path: req.url }, "request handled");
```
