import SwiftUI
import NavigationKit
import Swinject

// Back-always-home scenario: Confirm never pops to Search, deep-linked or
// not - its back control always dismisses the whole flow (see
// WatchlistConfirmView), landing the user back where they started rather
// than on a screen they may never have actually visited.
@MainActor
public final class WatchlistCoordinator: ObservableObject {
    @Published public var isPresented = false
    @Published public var path = NavigationPath()

    // Owned for the coordinator's lifetime, same reasoning as
    // NewsCoordinator.newsListViewModel: constructing it in `body` would
    // reset in-progress search text/results on every unrelated re-render.
    public let searchViewModel: WatchlistSearchViewModel

    private let container: Resolver

    public init(container: Resolver) {
        self.container = container
        self.searchViewModel = WatchlistSearchViewModel(service: container.resolve(WatchlistServicing.self)!)
    }

    public func handle(_ destination: WatchlistDestination) {
        isPresented = true
        switch destination {
        case .search:
            path = NavigationPath()
        case .confirm(let coinId, let coinName):
            path = NavigationPath()
            path.append(WatchlistRoute.confirm(coinId: coinId, coinName: coinName))
        }
    }

    public func dismiss() {
        isPresented = false
        path = NavigationPath()
    }

    public func showConfirm(coinId: String, coinName: String) {
        path.append(WatchlistRoute.confirm(coinId: coinId, coinName: coinName))
    }

    public func makeConfirmViewModel(coinId: String, coinName: String) -> WatchlistConfirmViewModel {
        WatchlistConfirmViewModel(
            coinId: coinId,
            coinName: coinName,
            service: container.resolve(WatchlistServicing.self)!
        )
    }
}
