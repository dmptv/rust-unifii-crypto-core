# crypto_core — Rust + UniFFI learning project

A small Rust core, wrapped via [UniFFI](https://mozilla.github.io/uniffi-rs/) into a native Swift API, built to
deliberately exercise the breadth of UniFFI's capabilities — not just one trivial function, but sync calls, typed
error propagation, callback-interface streaming, and async/await — on top of a real data source (CoinGecko REST +
Binance public WebSocket).

The Rust core is the sole gateway to the outside world: the SwiftUI client never calls a public API directly, it
only calls into the Rust core via UniFFI, mirroring a "platform-independent Rust logical core communicating with
the client via generic interfaces" architecture.

## Structure

- `crypto_core/` — the Rust crate (`cargo build`), UniFFI proc-macro exports (no `.udl` file), generated Swift
  bindings under `bindings/`, and the compiled `crypto_core.xcframework` for iOS device + simulator.
- `SDKBuild/` — a throwaway Tuist project whose only job is compiling `CryptoCoreKit`'s Swift wrapper together
  with the Rust core into `CryptoCoreKit.xcframework` (see "Distributing CryptoCoreKit as a closed-source SDK"
  below). Not part of the app workspace.
- `CryptoCoreKitSDK/` — the distributable SPM package: a `Package.swift` with a single `.binaryTarget` pointing at
  the compiled `CryptoCoreKit.xcframework` (tracked in git). No `.swift` source ships in this package.
- `App/` — a SwiftUI iOS app (project generated via [tuist](https://tuist.io) from `Project.swift`), split into
  Tuist modules:
  - `MarketsFeature` — a market dashboard streaming real trade prices from Binance's public WebSocket, pushed
    from Rust to Swift through a UniFFI callback interface.
  - `AsyncFeature` — the same price lookup exposed as a native Rust `async fn`, generated as a native Swift
    `async`/`await` function, including live error propagation (`Result<T, E>` → Swift `throws`).
  - `GrpcFeature` — Rust as a real gRPC *client* to an external service (Buf's public Eliza demo), returning raw
    protobuf wire bytes across the FFI boundary instead of a decoded type; Swift deserializes them itself using
    `ElizaProtoKit` (see "gRPC: Rust as a client to an external service" below).
  - `MarketsFeature`/`AsyncFeature`/`GrpcFeature` depend on `CryptoCoreKit` as an external SPM package (via
    `Tuist/Package.swift`), not as in-workspace source — exactly the way they'd depend on any third-party SDK.
  - The app target itself is the composition root, wiring all three features' view models together (see
    `App/Sources/RootView.swift`).
- `ElizaProtoKit/` — stands in for a backend team's proto-contract repository: publishes `eliza.proto` plus the
  Swift models `protoc --swift_out` generates from it. See "gRPC" below for why this is a separate package instead
  of source living inside `GrpcFeature`.

## What's demonstrated

| UniFFI feature | Where |
|---|---|
| Basic sync function + struct (`Record`) mapping | `get_price(coinId:) -> PriceInfo` |
| Typed error propagation (`Result` → `throws`) | `PriceError` (`RateLimited` / `Network` / `InvalidResponse`) |
| Callback interface (Rust → Swift push) | `TickerListener` trait, implemented as a Swift class |
| Reference-counted `Object` handles | `PriceTicker` (owns a background thread + WebSocket connection) |
| Native async/await | `get_price_async(coinId:) -> PriceInfo` |
| Raw bytes across the boundary (`Vec<u8>` → `Data`) | `ask_eliza(sentence:) -> Data` (protobuf wire bytes, decoded independently on each side) |

## Building

```bash
# 1. Build the Rust core for host + iOS targets
cd crypto_core
cargo build --release
cargo build --release --lib --target aarch64-apple-ios
cargo build --release --lib --target aarch64-apple-ios-sim

# 2. Generate Swift bindings
cargo run --release --bin uniffi-bindgen -- generate \
  --library target/release/libcrypto_core.dylib --language swift --out-dir ./bindings

# 3. Package the .xcframework
cp bindings/crypto_coreFFI.h include/
cp bindings/crypto_coreFFI.modulemap include/module.modulemap
xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release/libcrypto_core.a -headers include \
  -library target/aarch64-apple-ios-sim/release/libcrypto_core.a -headers include \
  -output crypto_core.xcframework

# 4. Generate and open the Xcode project
cd ../App
tuist generate
```

## Distributing CryptoCoreKit as a closed-source SDK

`App/` doesn't consume `CryptoCoreKit`'s Swift source directly — it depends on `CryptoCoreKitSDK`, a real SPM
package whose only target is a `.binaryTarget` pointing at a compiled `.xcframework`. No `.swift` file ships in
that package; consumers get a Mach-O binary plus its public `.swiftinterface` (type signatures, no
implementation).

To rebuild the SDK after changing `SDKBuild/Sources/crypto_core.swift` (e.g. after regenerating fresh UniFFI
bindings — see the note below):

```bash
cd SDKBuild
tuist generate

# Archive both platform slices with library evolution enabled, so the
# resulting framework has a stable, textual .swiftinterface instead of a
# compiler-version-locked .swiftmodule.
xcodebuild archive -workspace CryptoCoreKitSDKBuild.xcworkspace -scheme CryptoCoreKit \
  -destination "generic/platform=iOS" -archivePath ./build/CryptoCoreKit-iOS.xcarchive \
  SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive -workspace CryptoCoreKitSDKBuild.xcworkspace -scheme CryptoCoreKit \
  -destination "generic/platform=iOS Simulator" -archivePath ./build/CryptoCoreKit-iOS-Simulator.xcarchive \
  SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES EXCLUDED_ARCHS=x86_64

xcodebuild -create-xcframework \
  -framework build/CryptoCoreKit-iOS.xcarchive/Products/Library/Frameworks/CryptoCoreKit.framework \
  -framework build/CryptoCoreKit-iOS-Simulator.xcarchive/Products/Library/Frameworks/CryptoCoreKit.framework \
  -output CryptoCoreKit.xcframework

# Publish it into the SPM package that the app actually depends on.
cp -R CryptoCoreKit.xcframework ../CryptoCoreKitSDK/CryptoCoreKit.xcframework
cd ../App && tuist install --update && tuist generate
```

**Regenerating bindings note:** `SDKBuild/Sources/crypto_core.swift` is a *copy* of
`crypto_core/bindings/crypto_core.swift`, patched in two places to keep the Rust FFI module out of the SDK's
public/private interface (a UniFFI codegen detail that only matters once the wrapper ships as a compiled
framework, not as source):
1. `import crypto_coreFFI` → `@_implementationOnly import crypto_coreFFI`.
2. The two free functions that leak `RustBuffer` into a `public` signature
   (`FfiConverterTypePriceInfo_lift`/`_lower`) had `public` dropped — nothing outside the generated file calls
   them; UniFFI only emits them for multi-crate scenarios this project doesn't have.

Re-apply both edits after copying a freshly-regenerated `bindings/crypto_core.swift` into `SDKBuild/Sources/`.

## gRPC: Rust as a client to an external service

`ask_eliza(sentence:)` calls a real, public, unauthenticated gRPC service — Buf's Eliza demo
(`connectrpc.eliza.v1.ElizaService.Say` at `demo.connectrpc.com`) — via `tonic`. This is deliberately *not* about
using gRPC between Swift and Rust (UniFFI already solves that in-process call); it demonstrates the Rust core
acting as a gRPC client to a genuinely external service.

**The interesting design choice:** Rust doesn't hand Swift a decoded string. `tonic`/`prost` decode the gRPC
response into a Rust struct as part of making the call (unavoidable — that's how the generated client works), but
the Rust function immediately re-encodes it back to raw protobuf wire bytes (`prost::Message::encode_to_vec`) and
returns those bytes as-is. Swift deserializes them independently, using its own code generated from the *same*
`eliza.proto` — mirroring how a backend team's proto contract and a client team's generated code stay in sync via
one shared `.proto` file in a real multi-repo setup, each side running its own language's protoc plugin.

**Why `ElizaProtoKit` is a separate package** rather than proto-generated source living inside `GrpcFeature`: it
plays the same "team owns and publishes this contract" role as `CryptoCoreKitSDK` does for the compiled SDK —
`.package(path:)` here, `.package(url: "https://github.com/<backend-team>/ElizaProtoKit.git", from: "1.0.0")` in a
real multi-repo setup, same dependency mechanism either way.

**Regenerating `Sources/ElizaProtoKit/Generated/eliza.pb.swift` after changing `eliza.proto`:**

Ideally this would happen automatically via SwiftProtobuf's official SPM build plugin
(`.plugins: [.plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")]`) — but Tuist's project generation
doesn't run build-tool plugins declared by a *different* package against a local target, so the plugin silently
never executes and the target compiles with zero sources. The generated file is committed and produced by hand
instead:

```bash
# protoc-gen-swift's generated code must come from the exact same swift-protobuf
# version ElizaProtoKit depends on (currently 1.30.0) — a version mismatch
# produces a real compile error (_NameMap init signature changed between
# versions), not a warning. Homebrew only ships the latest protoc-gen-swift,
# so build the matching one from the already-resolved package checkout:
cd App/Tuist/.build/checkouts/swift-protobuf   # after `tuist install` in App/
swift build -c release --product protoc-gen-swift
cp .build/out/Products/Release/protoc-gen-swift ../../../../../ElizaProtoKit/.tools/protoc-gen-swift

cd ../../../../../ElizaProtoKit
protoc --plugin=protoc-gen-swift=.tools/protoc-gen-swift \
  --swift_out=Sources/ElizaProtoKit/Generated --swift_opt=Visibility=Public \
  --proto_path=proto proto/eliza.proto
```

`--swift_opt=Visibility=Public` matters — without it, `protoc-gen-swift` emits `internal` types, invisible to
`GrpcFeature` across the module boundary.

**Beta-SDK deployment target quirk:** `swift-protobuf`'s `PrivacyInfo.xcprivacy` resource forces Xcode to
synthesize an auxiliary resource-bundle target that Tuist's `PackageSettings.targetSettings` can't override by
name; on an SDK whose minimum supported deployment target is higher than the package's implicit default (iOS 27
beta here, floor 15.0 vs. the implicit 12.0), this bundle target fails to build. Fixed with a one-line patch after
every `tuist generate`, since the derived project isn't tracked in git:

```bash
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 26.0;/g' \
  App/Tuist/.build/tuist-derived/SwiftProtobuf/SwiftProtobuf.xcodeproj/project.pbxproj
```

## Working with the Xcode project (multi-developer workflow)

`App/CryptoCoreApp.xcodeproj` and `App/CryptoCoreApp.xcworkspace` are **generated, not committed** (see
`.gitignore`). `App/Project.swift` is the single source of truth for the project's targets, sources, and
dependencies — the same role a hand-maintained `.pbxproj` would normally play, except it's a plain Swift file that
diffs and merges cleanly.

This matters for more than one person working on the app: a raw `.xcodeproj` is a single sprawling XML-ish file
that Xcode rewrites on nearly every build, so two developers touching it at the same time reliably produce merge
conflicts in a file nobody can read by eye. With `Project.swift` as the only tracked artifact, there's nothing
project-shaped to conflict over — everyone regenerates their own `.xcodeproj`/`.xcworkspace` locally and never
commits it.

**Team workflow:**
- Never `git add` anything under `CryptoCoreApp.xcodeproj/` or `CryptoCoreApp.xcworkspace/` — they're gitignored
  already, so this should never come up.
- **New ordinary source files (a view, a view model, etc.) don't need `Project.swift` touched at all.**
  `Project.swift` declares `sources: ["Sources/**"]` — a glob, not an explicit file list — so any `.swift` file
  saved anywhere under `Sources/` is picked up automatically on the next `tuist generate`. Create it the normal
  way (Xcode's File ▸ New, drag-and-drop, whatever) as long as it lands inside `Sources/`. Since the resulting
  `.pbxproj` is never committed, two developers adding files at the same time never touch the same tracked file —
  there's nothing to conflict over.
- `Project.swift` only needs an actual edit for *structural* changes: a new target, a new external dependency (an
  SPM package, another `.xcframework`), a build-setting/deployment-target change, or a source file living outside
  the `Sources/**` glob.
- After pulling changes that touch `Project.swift` (or the first time you open the project), run `tuist generate`
  again before building — this repo pins the exact `tuist` version via `.mise.toml` (`4.79.4`) so everyone
  generates an identical project structure; run `mise install` once to pick it up.
