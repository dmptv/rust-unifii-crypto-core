import ComposableArchitecture
import CryptoCoreKit
import Dependencies
import DependencyContainerKit
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

public protocol WatchlistClientProtocol: Sendable {
    func searchCoins(_ query: String) async throws -> [CoinSearchResult]
    func add(_ coin: WatchlistedCoin) async
}

public final class LiveWatchlistClient: WatchlistClientProtocol, Sendable {
    private let store: Store

    private init(store: Store) {
        self.store = store
    }

    // Store's init touches ModelContainer.mainContext, which is
    // @MainActor-isolated; live() itself isn't, so this asserts what's
    // true at runtime (first access happens on the main actor) rather
    // than threading @MainActor through the whole call chain up to
    // AppDependencyContainer.
    public static func live() -> LiveWatchlistClient {
        let store = MainActor.assumeIsolated { Store() }
        return LiveWatchlistClient(store: store)
    }

    public func searchCoins(_ query: String) async throws -> [CoinSearchResult] {
        try await Task.detached(priority: .userInitiated) {
            try CryptoCoreKit.searchCoins(query: query)
        }.value
    }

    public func add(_ coin: WatchlistedCoin) async {
        await store.add(coin)
    }
}

private enum WatchlistClientKey: DependencyKey {
    // Point of glue: resolves whatever CryptoCoreApp registered into the
    // shared Swinject container at launch, rather than calling
    // LiveWatchlistClient.live() directly.
    static let liveValue: any WatchlistClientProtocol = AppDependencyContainer.shared.resolve(WatchlistClientProtocol.self)!
}

extension DependencyValues {
    public var watchlistClient: any WatchlistClientProtocol {
        get { self[WatchlistClientKey.self] }
        set { self[WatchlistClientKey.self] = newValue }
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
        // Core Data's own retry-on-missing-directory recovery is
        // observed to be flaky on this Xcode 27 beta simulator (works on
        // one launch, EXC_BREAKPOINT-crashes the container on the next,
        // same app, same machine) - don't depend on it. Guarantee the
        // directory exists ourselves before ModelContainer ever tries to
        // create the store file inside it.
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        let schema = Schema([WatchlistedCoinModel.self])
        // Named explicitly so this doesn't collide with NewsClient's
        // Store, which also creates a ModelContainer with no configured
        // URL - both would otherwise resolve to the same default.store
        // file with two incompatible schemas.
        let configuration = ModelConfiguration("WatchlistStore", schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
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
