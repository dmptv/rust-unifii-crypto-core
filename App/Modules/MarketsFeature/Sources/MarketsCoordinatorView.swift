import SwiftUI

public struct MarketsCoordinatorView: View {
    @ObservedObject var coordinator: MarketsCoordinator
    private let tickerViewModel: TickerViewModel

    public init(coordinator: MarketsCoordinator, tickerViewModel: TickerViewModel) {
        self.coordinator = coordinator
        self.tickerViewModel = tickerViewModel
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            LiveDashboardView(
                viewModel: tickerViewModel,
                onSelectCoin: { coinId in coordinator.showCoinDetail(coinId: coinId) },
                onBrowseAllCoins: { coordinator.showCoinList() }
            )
            .navigationDestination(for: MarketsRoute.self) { route in
                switch route {
                case .coinDetail(let coinId):
                    CoinDetailView(
                        viewModel: coordinator.makeCoinDetailViewModel(coinId: coinId),
                        onSetAlert: { coordinator.showPriceAlert(coinId: coinId) }
                    )
                case .priceAlert(let coinId):
                    PriceAlertView(coinId: coinId)
                case .coinList:
                    CoinListView(
                        viewModel: coordinator.makeCoinListViewModel(),
                        onSelect: { coinId in coordinator.showCoinDetail(coinId: coinId) }
                    )
                }
            }
        }
    }
}
