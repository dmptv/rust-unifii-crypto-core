import ComposableArchitecture
import Foundation
import MarketsFeature
import NavigationKit
import NewsFeature
import WatchlistFeature

// Decodes the "destination" object out of a push payload's userInfo and
// routes it to the right place. Markets is TCA now, so it gets an Action
// sent to its Store directly; News/Watchlist are still Coordinator+Swinject
// until they're migrated too - this file is a deliberate hybrid during the
// transition, not a design decision to keep permanently.
@MainActor
final class DeepLinkRouter {
    private let marketsStore: StoreOf<MarketsFeature>
    private let newsCoordinator: NewsCoordinator
    private let watchlistCoordinator: WatchlistCoordinator
    private let tabSelection: TabSelectionModel

    init(
        marketsStore: StoreOf<MarketsFeature>,
        newsCoordinator: NewsCoordinator,
        watchlistCoordinator: WatchlistCoordinator,
        tabSelection: TabSelectionModel
    ) {
        self.marketsStore = marketsStore
        self.newsCoordinator = newsCoordinator
        self.watchlistCoordinator = watchlistCoordinator
        self.tabSelection = tabSelection
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
        case .markets(let marketsDestination):
            tabSelection.selectedTab = .live
            switch marketsDestination {
            case .coinDetail(.show(let coinId, let next)):
                marketsStore.send(.deepLinkToCoinDetail(coinId: coinId, thenPriceAlert: next != nil))
            }
        case .news(let d):
            newsCoordinator.handle(d)
        case .watchlist(let d):
            watchlistCoordinator.handle(d)
        }
    }
}
