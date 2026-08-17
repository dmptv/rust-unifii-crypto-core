import ComposableArchitecture
import SwiftUI

public struct MarketsCoordinatorView: View {
    @Bindable var store: StoreOf<MarketsFeature>

    public init(store: StoreOf<MarketsFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            LiveDashboardView(store: store)
        } destination: { store in
            switch store.case {
            case let .coinDetail(store):
                CoinDetailView(store: store)
            case let .priceAlert(store):
                PriceAlertView(store: store)
            case let .coinList(store):
                CoinListView(store: store)
            }
        }
    }
}
