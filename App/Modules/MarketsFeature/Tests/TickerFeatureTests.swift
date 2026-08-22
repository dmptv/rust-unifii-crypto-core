import ComposableArchitecture
import CryptoCoreKit
import XCTest

@testable import MarketsFeature

// Unit test: TickerClient is a fake, no real PriceTicker/WebSocket involved
// - isolates the reducer's own logic from the real Rust/FFI boundary,
// unlike CryptoCoreKitTests (which deliberately hits the real thing).
@MainActor
final class TickerFeatureTests: XCTestCase {
    func testStartReceivesUpdateThenStopStopsTheTicker() async {
        let fakeTicker = FakeTicker()
        let capturedListener = LockIsolated<TickerListener?>(nil)

        let store = TestStore(initialState: TickerFeature.State()) {
            TickerFeature()
        } withDependencies: {
            $0.tickerClient = TickerClient(makeTicker: { _, listener in
                capturedListener.setValue(listener)
                return fakeTicker
            })
        }

        await store.send(.startTapped) {
            $0.isStreaming = true
        }

        capturedListener.value?.onUpdate(ticker: PriceInfo(coinId: "BTCUSDT", usdPrice: 65000))

        await store.receive(\.priceUpdate) {
            $0.prices["BTCUSDT"] = 65000
            $0.baselines["BTCUSDT"] = 65000
            $0.history["BTCUSDT"] = [65000]
        }

        await store.send(.stopTapped) {
            $0.isStreaming = false
        }
        await store.finish()

        XCTAssertTrue(fakeTicker.stopCalled)
    }
}

private final class FakeTicker: PriceTickerProtocol, @unchecked Sendable {
    private(set) var stopCalled = false
    func stop() { stopCalled = true }
}
