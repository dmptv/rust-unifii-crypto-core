import SwiftUI
import NavigationKit
import Swinject

// Push-onto-current-stack scenario: a deep link into CoinDetail (optionally
// continuing to PriceAlerts) is appended to whatever's already on the
// Markets tab's stack rather than replacing it or presenting a new one.
@MainActor
public final class MarketsCoordinator: ObservableObject {
    @Published public var path = NavigationPath()

    private let container: Resolver

    public init(container: Resolver) {
        self.container = container
    }

    public func handle(_ destination: MarketsDestination) {
        switch destination {
        case .coinDetail(let coinDetailDestination):
            handle(coinDetailDestination)
        }
    }

    public func handle(_ destination: CoinDetailDestination) {
        switch destination {
        case .show(let coinId, let next):
            path.append(MarketsRoute.coinDetail(coinId: coinId))
            if let next {
                handle(next)
            }
        }
    }

    public func handle(_ destination: PriceAlertDestination) {
        switch destination {
        case .show(let coinId):
            path.append(MarketsRoute.priceAlert(coinId: coinId))
        }
    }

    public func showCoinDetail(coinId: String) {
        handle(CoinDetailDestination.show(coinId: coinId, next: nil))
    }

    public func showPriceAlert(coinId: String) {
        handle(PriceAlertDestination.show(coinId: coinId))
    }

    public func showCoinList() {
        path.append(MarketsRoute.coinList)
    }

    public func makeCoinDetailViewModel(coinId: String) -> CoinDetailViewModel {
        CoinDetailViewModel(coinId: coinId, service: container.resolve(MarketsServicing.self)!)
    }

    public func makeCoinListViewModel() -> CoinListViewModel {
        CoinListViewModel(service: container.resolve(MarketsServicing.self)!)
    }
}
