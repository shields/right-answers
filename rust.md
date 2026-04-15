# Rust

Use **edition 2024**. For simple CLIs, parse arguments manually rather than using `clap`.

## Linting

Deny all Clippy lint groups, including `nursery` and `cargo`:

```toml
[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "deny", priority = -1 }
nursery = { level = "deny", priority = -1 }
cargo = { level = "deny", priority = -1 }
```

## Test coverage

Use `cargo llvm-cov` on nightly. Cfg-gate `#[coverage(off)]` on `main()` and
register the cfg in workspace lints:

```rust
#![cfg_attr(coverage_nightly, feature(coverage_attribute))]

#[cfg_attr(coverage_nightly, coverage(off))]
fn main() -> ExitCode {
```

```toml
unexpected_cfgs = { level = "warn", check-cfg = ['cfg(coverage_nightly)'] }
```
