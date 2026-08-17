import ComposableArchitecture
import SwiftUI

public struct NewsCoordinatorView: View {
    @Bindable var store: StoreOf<NewsFeature>

    public init(store: StoreOf<NewsFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            NewsListView(store: store)
        } destination: { store in
            switch store.case {
            case let .articleDetail(store):
                NewsArticleDetailView(store: store)
            }
        }
    }
}
