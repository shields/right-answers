# Swift

Target **Swift 6.3** with language mode 6 and strict concurrency. Treat warnings
as errors (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in Xcode;
`.treatWarningsAsErrors()` in `Package.swift`).

## Tooling

Use Swift Package Manager for libraries, internal modules, and CLIs. Reserve
Xcode projects for app targets that require resources, entitlements, or
extensions. Do not use CocoaPods or Carthage.

## Linting and formatting

Use [swift-format](https://github.com/swiftlang/swift-format), bundled with the
Swift toolchain. Run `swift format lint --strict` in CI and
`swift format format -i -r .` locally. Do not add SwiftLint.

## Testing

Use [Swift Testing](https://developer.apple.com/xcode/swift-testing/) for new
code (`@Test`, `#expect`, `#require`). Migrate XCTest suites opportunistically.

Run with coverage and process the resulting `.profdata` with `xcrun llvm-cov`:

```bash
swift test --enable-code-coverage
```

## CLIs

Use [swift-argument-parser](https://github.com/apple/swift-argument-parser) for
command-line tools.

## Logging

Use [`os.Logger`](https://developer.apple.com/documentation/os/logger) for app
code on Apple platforms. For cross-platform libraries that also run on Linux,
use [swift-log](https://github.com/apple/swift-log).
