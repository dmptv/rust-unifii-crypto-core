import CryptoCoreKit
import Foundation
import NavigationKit

// Search goes through the Rust node like every other public-API call;
// the watchlist itself is local device state, so it's plain UserDefaults
// rather than anything crossing the FFI boundary.
public final class RustWatchlistService: WatchlistServicing {
    private let defaultsKey = "com.example.cryptocoreapp.watchlist"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func searchCoins(query: String) async throws -> [CoinSearchResult] {
        try await Task.detached(priority: .userInitiated) {
            try CryptoCoreKit.searchCoins(query: query)
        }.value
    }

    public func add(_ coin: WatchlistedCoin) {
        var coins = watchlistedCoins()
        guard !coins.contains(where: { $0.coinId == coin.coinId }) else { return }
        coins.append(coin)
        guard let data = try? JSONEncoder().encode(coins) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    public func watchlistedCoins() -> [WatchlistedCoin] {
        guard let data = defaults.data(forKey: defaultsKey),
              let coins = try? JSONDecoder().decode([WatchlistedCoin].self, from: data) else {
            return []
        }
        return coins
    }
}
