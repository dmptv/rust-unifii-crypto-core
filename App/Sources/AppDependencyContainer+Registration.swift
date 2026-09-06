import DependencyContainerKit
import MarketsFeature
import NewsFeature
import Swinject
import WatchlistFeature

// The composition root is the only place that knows about every feature's
// concrete Live* type at once, so registration lives here rather than
// inside DependencyContainerKit itself (which stays feature-agnostic).
extension AppDependencyContainer {
    static func registerDependencies() {
        shared.register(TickerClientProtocol.self) { _ in LiveTickerClient() }
            .inObjectScope(.container)
        shared.register(NewsClientProtocol.self) { _ in LiveNewsClient.live() }
            .inObjectScope(.container)
        shared.register(WatchlistClientProtocol.self) { _ in LiveWatchlistClient.live() }
            .inObjectScope(.container)
    }

    // Forces the News/Watchlist clients off Swinject's lazy-resolve path,
    // on the main actor, *after* the app has actually finished launching -
    // not from CryptoCoreApp.init() (too early: the sandbox's Application
    // Support directory isn't guaranteed to exist yet on a fresh install,
    // which made SwiftData's ModelContainer creation fail outright). Both
    // live() implementations construct a @MainActor-isolated SwiftData
    // Store via MainActor.assumeIsolated, which traps (EXC_BREAKPOINT) if
    // the first real resolve happens later, from whatever thread first
    // touches @Dependency(\.newsClient)/@Dependency(\.watchlistClient)
    // inside an Effect - so this still needs to run eagerly, just later.
    @MainActor
    static func warmUpMainActorClients() {
        _ = shared.resolve(NewsClientProtocol.self)
        _ = shared.resolve(WatchlistClientProtocol.self)
    }
}
