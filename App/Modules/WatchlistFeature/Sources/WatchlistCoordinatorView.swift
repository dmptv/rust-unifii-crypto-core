import ComposableArchitecture
import SwiftUI

public struct WatchlistCoordinatorView: View {
    @Bindable var store: StoreOf<WatchlistFeature>

    public init(store: StoreOf<WatchlistFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            WatchlistSearchView(store: store.scope(state: \.search, action: \.search))
        } destination: { store in
            switch store.case {
            case let .confirm(store):
                WatchlistConfirmView(store: store)
            }
        }
    }
}
