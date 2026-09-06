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
}
