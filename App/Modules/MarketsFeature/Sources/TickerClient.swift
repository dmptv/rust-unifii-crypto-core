import ComposableArchitecture
import CryptoCoreKit

// The seam that makes TickerFeature testable: PriceTicker's own
// constructor is concrete (not part of PriceTickerProtocol, since UniFFI
// only puts instance methods like `stop()` in the generated protocol, not
// initializers). Wrapping construction in a @Dependency closure lets tests
// substitute a fake ticker instead of opening a real Binance WebSocket.
public struct TickerClient: Sendable {
    public var makeTicker: @Sendable (_ symbols: [String], _ listener: TickerListener) throws -> any PriceTickerProtocol
}

extension TickerClient: DependencyKey {
    public static let liveValue = TickerClient(
        makeTicker: { symbols, listener in
            try PriceTicker(symbols: symbols, listener: listener)
        }
    )
}

extension DependencyValues {
    public var tickerClient: TickerClient {
        get { self[TickerClient.self] }
        set { self[TickerClient.self] = newValue }
    }
}
