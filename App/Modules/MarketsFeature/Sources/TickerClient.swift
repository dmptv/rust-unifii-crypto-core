import ComposableArchitecture
import CryptoCoreKit
import DependencyContainerKit

// The seam that makes TickerFeature testable: PriceTicker's own
// constructor is concrete (not part of PriceTickerProtocol, since UniFFI
// only puts instance methods like `stop()` in the generated protocol, not
// initializers). Wrapping construction behind a protocol lets tests
// substitute a fake ticker instead of opening a real Binance WebSocket.
public protocol TickerClientProtocol: Sendable {
    func makeTicker(_ symbols: [String], port: UInt16, _ listener: TickerListener) throws -> any PriceTickerProtocol
}

public final class LiveTickerClient: TickerClientProtocol, Sendable {
    public init() {}

    public func makeTicker(_ symbols: [String], port: UInt16, _ listener: TickerListener) throws -> any PriceTickerProtocol {
        try PriceTicker(symbols: symbols, port: port, listener: listener)
    }
}

private enum TickerClientKey: DependencyKey {
    // Point of glue: resolves whatever CryptoCoreApp registered into the
    // shared Swinject container at launch, rather than constructing
    // LiveTickerClient directly. The Reducer above never sees Swinject -
    // it only ever sees `any TickerClientProtocol` via @Dependency.
    static let liveValue: any TickerClientProtocol = AppDependencyContainer.shared.resolve(TickerClientProtocol.self)!
}

extension DependencyValues {
    public var tickerClient: any TickerClientProtocol {
        get { self[TickerClientKey.self] }
        set { self[TickerClientKey.self] = newValue }
    }
}
