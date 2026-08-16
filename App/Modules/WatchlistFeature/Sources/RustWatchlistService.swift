import CryptoCoreKit
import Foundation
import NavigationKit
import SwiftData

// Search goes through the Rust node like every other public-API call; the
// watchlist itself is local device state, persisted with SwiftData rather
// than crossing the FFI boundary.
public final class RustWatchlistService: WatchlistServicing {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func searchCoins(query: String) async throws -> [CoinSearchResult] {
        try await Task.detached(priority: .userInitiated) {
            try CryptoCoreKit.searchCoins(query: query)
        }.value
    }

    public func add(_ coin: WatchlistedCoin) {
        let coinId = coin.coinId
        let descriptor = FetchDescriptor<WatchlistedCoinModel>(
            predicate: #Predicate { $0.coinId == coinId }
        )
        guard (try? modelContext.fetchCount(descriptor)) == 0 else { return }
        modelContext.insert(WatchlistedCoinModel(coinId: coin.coinId, coinName: coin.coinName))
        try? modelContext.save()
    }

    public func watchlistedCoins() -> [WatchlistedCoin] {
        let descriptor = FetchDescriptor<WatchlistedCoinModel>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let models = (try? modelContext.fetch(descriptor)) ?? []
        return models.map { WatchlistedCoin(coinId: $0.coinId, coinName: $0.coinName) }
    }
}
