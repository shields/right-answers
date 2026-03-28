# TypeScript/JavaScript

## Tooling

Use [Bun](https://bun.sh/) as the package manager and test runner. Use
`bun install` and `bun.lock` for dependency management. Do not use npm, yarn,
or pnpm.

All projects must use ESM (`"type": "module"` in `package.json`).

## TypeScript configuration

Use TypeScript in type-checking-only mode (`noEmit: true`). Enable
`erasableSyntaxOnly` for compatibility with Node.js native type stripping.

Enable all strict checks and then some:

```jsonc
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "erasableSyntaxOnly": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

Key flags beyond `strict`:

- **`noUncheckedIndexedAccess`** --- index signatures return `T | undefined`,
  catching a common class of runtime errors.
- **`exactOptionalPropertyTypes`** --- distinguishes between a missing property
  and one explicitly set to `undefined`.
- **`erasableSyntaxOnly`** --- ensures the code runs under Node.js type
  stripping without a build step.

## Linting

Use [ESLint](https://eslint.org/) with
[typescript-eslint](https://typescript-eslint.io/) and
[eslint-plugin-unicorn](https://github.com/sindresorhus/eslint-plugin-unicorn).

Enable the strictest type-checked rule sets:

- `tseslint.configs.strictTypeChecked`
- `tseslint.configs.stylisticTypeChecked`
- `unicorn.configs.unopinionated`

Require `eqeqeq`.

Starter `eslint.config.ts`:

```ts
import eslint from "@eslint/js";
import unicorn from "eslint-plugin-unicorn";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["node_modules/"] },
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  unicorn.configs.unopinionated,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      eqeqeq: "error",
    },
  },
);
```

## Testing

Use `bun test` with 100% coverage thresholds. Configure in `bunfig.toml`:

```toml
[test]
coverageThreshold = { lines = 1.0, functions = 1.0, statements = 1.0 }
```

## Makefile example

```makefile
.PHONY: lint check test

lint:
	bun run lint

check:
	tsc

test:
	bun test --coverage
```
