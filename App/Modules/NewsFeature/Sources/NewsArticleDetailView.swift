import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct NewsArticleDetailView: View {
    let store: StoreOf<NewsArticleDetailFeature>

    public init(store: StoreOf<NewsArticleDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                if let article = store.article {
                    Text(article.title)
                        .font(DSFont.sectionTitle)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(article.publishedAt)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.textSecondary)
                    Text(article.summary)
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.textSecondary)
                    if let url = URL(string: article.url) {
                        Link("Read full article", destination: url)
                            .font(.callout.bold())
                    }
                }
            }
            .padding()
        }
        .requestState(isLoading: store.isLoading, errorMessage: store.errorMessage)
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle(store.article?.title ?? "Article")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.send(.onAppear)
        }
    }
}
