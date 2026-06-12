# Rust

Use **edition 2024**. For simple CLIs, parse arguments manually rather than
using `clap`.

## Toolchain

Pin the latest stable Rust release in `rust-toolchain.toml` (look it up fresh —
don't guess from memory):

```toml
[toolchain]
channel = "X.Y.Z" # the current stable release, fully specified
components = ["clippy", "rustfmt"]
profile = "minimal"
```

Both local `cargo` and CI pick this up automatically. Renovate updates the
channel like action SHAs.

## Linting

Set the `all`, `pedantic`, `nursery`, and `cargo` lint groups to `deny`, and opt
in to the safety-relevant `restriction` lints by name —
[Clippy disrecommends enabling all of `restriction`](https://doc.rust-lang.org/stable/clippy/lints.html#restriction)
because it contains contradictory and stylistic lints:

```toml
[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "deny", priority = -1 }
nursery = { level = "deny", priority = -1 }
cargo = { level = "deny", priority = -1 }

# Panic safety
string_slice                    = "deny"
indexing_slicing                = "deny"
unwrap_used                     = "deny"
panic                           = "deny"
todo                            = "deny"
unimplemented                   = "deny"
unreachable                     = "deny"
get_unwrap                      = "deny"
unwrap_in_result                = "deny"
panic_in_result_fn              = "deny"
unchecked_time_subtraction      = "deny"
# Silent-failure
unused_result_ok                = "deny"
map_err_ignore                  = "deny"
assertions_on_result_states     = "deny"
# Unsafe discipline (redundant with forbid(unsafe_code), kept for portability)
mem_forget                      = "deny"
undocumented_unsafe_blocks      = "deny"
multiple_unsafe_ops_per_block   = "deny"
unnecessary_safety_doc          = "deny"
unnecessary_safety_comment      = "deny"
# Numbers (the rest live in pedantic)
float_cmp_const                 = "deny"
lossy_float_literal             = "deny"
# Easy wins
dbg_macro                       = "deny"
infallible_try_from             = "deny"
clone_on_ref_ptr                = "deny"
verbose_file_reads              = "deny"
tests_outside_test_module       = "deny"
# Force every suppression deliberate + documented
allow_attributes                = "deny"
allow_attributes_without_reason = "deny"
```

The restriction set follows
[Schwartz](https://emschwartz.me/your-clippy-config-should-be-stricter/), minus
`arithmetic_side_effects`: in practice almost every fire is a capacity hint or a
bounded loop counter where overflow can't happen, so the required
`saturating_add` / `checked_*` annotations are noise.

Add a `clippy.toml` at the workspace root so the in-test exceptions apply to
`unwrap`/`panic`/indexing/`dbg!` inside `#[test]` bodies:

```toml
allow-indexing-slicing-in-tests = true
allow-panic-in-tests = true
allow-unwrap-in-tests = true
allow-dbg-in-tests = true
```

`allow-*-in-tests` only covers `#[test]` bodies, not shared helpers. Integration
test files (`tests/*.rs`) put their `#[test]` functions at module root, so
`tests_outside_test_module` and `unwrap_used` both fire — suppress them at the
top of the file:

```rust
#![expect(
    clippy::tests_outside_test_module,
    reason = "Cargo integration tests live at the file's module root"
)]
#![expect(
    clippy::unwrap_used,
    reason = "tests can panic on setup failures; covers shared helpers too"
)]
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
