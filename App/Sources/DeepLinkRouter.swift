import Foundation
import MarketsFeature
import NavigationKit
import NewsFeature
import WatchlistFeature

// Decodes the "destination" object out of a push payload's userInfo and
// delegates straight to the matching coordinator's handle(_:) — the same
// entry point each coordinator already exposes for its own deep-link enum.
// This is the only place that needs to know all three coordinators exist.
@MainActor
final class DeepLinkRouter {
    private let marketsCoordinator: MarketsCoordinator
    private let newsCoordinator: NewsCoordinator
    private let watchlistCoordinator: WatchlistCoordinator

    init(
        marketsCoordinator: MarketsCoordinator,
        newsCoordinator: NewsCoordinator,
        watchlistCoordinator: WatchlistCoordinator
    ) {
        self.marketsCoordinator = marketsCoordinator
        self.newsCoordinator = newsCoordinator
        self.watchlistCoordinator = watchlistCoordinator
    }

    func handle(userInfo: [AnyHashable: Any]) {
        guard let destinationObject = userInfo["destination"] else { return }
        guard JSONSerialization.isValidJSONObject(destinationObject),
              let data = try? JSONSerialization.data(withJSONObject: destinationObject) else {
            return
        }
        guard let destination = try? JSONDecoder().decode(AppDestination.self, from: data) else {
            return
        }
        route(destination)
    }

    func route(_ destination: AppDestination) {
        switch destination {
        case .markets(let d):
            marketsCoordinator.handle(d)
        case .news(let d):
            newsCoordinator.handle(d)
        case .watchlist(let d):
            watchlistCoordinator.handle(d)
        }
    }
}
