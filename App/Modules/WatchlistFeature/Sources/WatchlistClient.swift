import ComposableArchitecture
import CryptoCoreKit
import Dependencies
import Foundation
import SwiftData

// TCA's replacement for WatchlistAssembly/RustWatchlistService: search hits
// the Rust node like every other public-API call, while the watchlist
// itself is local device state persisted with SwiftData - same offline/
// online split as NewsClient, minus the caching (there's nothing to fall
// back to here; the watchlist *is* the local store).
public struct WatchlistedCoin: Codable, Sendable, Equatable, Identifiable {
    public var id: String { coinId }
    public let coinId: String
    public let coinName: String

    public init(coinId: String, coinName: String) {
        self.coinId = coinId
        self.coinName = coinName
    }
}

public struct WatchlistClient: Sendable {
    public var searchCoins: @Sendable (_ query: String) async throws -> [CoinSearchResult]
    public var add: @Sendable (WatchlistedCoin) async -> Void
}

extension WatchlistClient: DependencyKey {
    public static let liveValue: WatchlistClient = {
        // Store's init touches ModelContainer.mainContext, which is
        // @MainActor-isolated; liveValue's own initializer isn't, so this
        // asserts what's true at runtime (first access happens on the main
        // actor) rather than threading @MainActor through DependencyKey.
        let store = MainActor.assumeIsolated { Store() }
        return WatchlistClient(
            searchCoins: { query in
                try await Task.detached(priority: .userInitiated) {
                    try CryptoCoreKit.searchCoins(query: query)
                }.value
            },
            add: { coin in await store.add(coin) }
        )
    }()
}

extension DependencyValues {
    public var watchlistClient: WatchlistClient {
        get { self[WatchlistClient.self] }
        set { self[WatchlistClient.self] = newValue }
    }
}

// ModelContext's Sendable conformance is unavailable, so it can only ever
// be touched from a single isolation domain - this class is pinned to the
// main actor for that reason. @unchecked Sendable is safe here because
// isolation, not the annotation, is what actually protects modelContext;
// the annotation only lets `store` be captured by the @Sendable closure
// above.
@MainActor
private final class Store: @unchecked Sendable {
    private let modelContext: ModelContext

    init() {
        let schema = Schema([WatchlistedCoinModel.self])
        do {
            let container = try ModelContainer(for: schema)
            self.modelContext = container.mainContext
        } catch {
            fatalError("Failed to create SwiftData ModelContainer for Watchlist: \(error)")
        }
    }

    func add(_ coin: WatchlistedCoin) {
        let coinId = coin.coinId
        let descriptor = FetchDescriptor<WatchlistedCoinModel>(
            predicate: #Predicate { $0.coinId == coinId }
        )
        guard (try? modelContext.fetchCount(descriptor)) == 0 else { return }
        modelContext.insert(WatchlistedCoinModel(coinId: coin.coinId, coinName: coin.coinName))
        try? modelContext.save()
    }
}
