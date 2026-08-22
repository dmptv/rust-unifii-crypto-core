import CryptoCoreKit
import XCTest

// PriceTicker::new spawns a real background thread that connects to the
// real Binance WebSocket (see crypto_core/src/lib.rs) - same philosophy as
// crypto_core's own `network_tests` module (real CoinGecko calls, no
// mocking), so this test hits the real socket too rather than faking it.
final class PriceTickerLifetimeTests: XCTestCase {
    func testDeinitReleasesRustArc() throws {
        weak var weakRef: PriceTicker?

        try autoreleasepool {
            let ticker = try PriceTicker(symbols: ["btcusdt"], listener: FakeTickerListener())
            weakRef = ticker
            XCTAssertNotNil(weakRef)
            ticker.stop()
        }

        XCTAssertNil(weakRef, "PriceTicker and its underlying Rust Arc were not released")
    }
}

private final class FakeTickerListener: TickerListener {
    func onUpdate(ticker: PriceInfo) {}
    func onError(message: String) {}
}
