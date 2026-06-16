<!--
Copyright © 2026 Michael Shields

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Swift

Target **Swift 6.3** with language mode 6 and strict concurrency. Treat warnings
as errors (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in Xcode;
[`.treatAllWarnings(as: .error)`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0480-swiftpm-warning-control.md)
in `swiftSettings` in `Package.swift`).

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
