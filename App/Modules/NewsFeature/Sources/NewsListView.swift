import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct NewsListView: View {
    let store: StoreOf<NewsFeature>

    public init(store: StoreOf<NewsFeature>) {
        self.store = store
    }

    public var body: some View {
        List(store.articles, id: \.id) { article in
            Button {
                store.send(.articleTapped(article.id))
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(DSFont.headline)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(article.publishedAt)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            .listRowBackground(DSColor.background)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .requestState(isLoading: store.isLoading, errorMessage: store.errorMessage)
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.send(.onAppear)
        }
    }
}
