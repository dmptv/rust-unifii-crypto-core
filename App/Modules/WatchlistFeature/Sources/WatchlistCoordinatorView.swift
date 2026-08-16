import SwiftUI

public struct WatchlistCoordinatorView: View {
    @ObservedObject var coordinator: WatchlistCoordinator

    public init(coordinator: WatchlistCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            WatchlistSearchView(
                viewModel: coordinator.searchViewModel,
                onSelect: { coinId, coinName in
                    coordinator.showConfirm(coinId: coinId, coinName: coinName)
                }
            )
            .navigationDestination(for: WatchlistRoute.self) { route in
                switch route {
                case .confirm(let coinId, let coinName):
                    WatchlistConfirmView(
                        viewModel: coordinator.makeConfirmViewModel(coinId: coinId, coinName: coinName),
                        onDismiss: { coordinator.dismiss() }
                    )
                }
            }
        }
    }
}
