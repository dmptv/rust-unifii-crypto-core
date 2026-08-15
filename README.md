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
- `App/` — a SwiftUI iOS app (project generated via [tuist](https://tuist.io) from `Project.swift`) consuming the
  `.xcframework`, with two tabs:
  - **Live** — a market dashboard streaming real trade prices from Binance's public WebSocket, pushed from Rust to
    Swift through a UniFFI callback interface.
  - **Async** — the same price lookup exposed as a native Rust `async fn`, generated as a native Swift
    `async`/`await` function, including live error propagation (`Result<T, E>` → Swift `throws`).

## What's demonstrated

| UniFFI feature | Where |
|---|---|
| Basic sync function + struct (`Record`) mapping | `get_price(coinId:) -> PriceInfo` |
| Typed error propagation (`Result` → `throws`) | `PriceError` (`RateLimited` / `Network` / `InvalidResponse`) |
| Callback interface (Rust → Swift push) | `TickerListener` trait, implemented as a Swift class |
| Reference-counted `Object` handles | `PriceTicker` (owns a background thread + WebSocket connection) |
| Native async/await | `get_price_async(coinId:) -> PriceInfo` |

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
