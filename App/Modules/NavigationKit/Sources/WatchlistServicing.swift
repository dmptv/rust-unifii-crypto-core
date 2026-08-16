import CryptoCoreKit

public struct WatchlistedCoin: Codable, Sendable, Equatable, Identifiable {
    public var id: String { coinId }
    public let coinId: String
    public let coinName: String

    public init(coinId: String, coinName: String) {
        self.coinId = coinId
        self.coinName = coinName
    }
}

// Search goes through the Rust node like every other public-API call;
// the watchlist itself is local device state, not a backend concept.
public protocol WatchlistServicing {
    func searchCoins(query: String) async throws -> [CoinSearchResult]
    func add(_ coin: WatchlistedCoin)
    func watchlistedCoins() -> [WatchlistedCoin]
}
