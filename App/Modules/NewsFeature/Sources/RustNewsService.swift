import CryptoCoreKit
import Foundation
import NavigationKit
import SwiftData

// getNews is a synchronous, network-calling FFI function (it fetches and
// parses CoinDesk's RSS feed); hop off the caller's thread the same way
// RustMarketsService does for getCoinDetails.
//
// Offline-first: a successful fetch refreshes a local SwiftData cache of
// the last-seen articles; a failed fetch (no network) falls back to
// whatever's cached instead of leaving the screen empty.
public final class RustNewsService: NewsServicing {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func articles() async throws -> [NewsArticle] {
        do {
            let fresh = try await Task.detached(priority: .userInitiated) {
                try getNews()
            }.value
            cache(fresh)
            return fresh
        } catch {
            let cached = cachedArticles()
            guard !cached.isEmpty else { throw error }
            return cached
        }
    }

    private func cache(_ articles: [NewsArticle]) {
        let existing = (try? modelContext.fetch(FetchDescriptor<CachedNewsArticleModel>())) ?? []
        for model in existing {
            modelContext.delete(model)
        }
        for article in articles {
            modelContext.insert(
                CachedNewsArticleModel(
                    id: article.id,
                    title: article.title,
                    summary: article.summary,
                    url: article.url,
                    publishedAt: article.publishedAt
                )
            )
        }
        try? modelContext.save()
    }

    private func cachedArticles() -> [NewsArticle] {
        let descriptor = FetchDescriptor<CachedNewsArticleModel>(
            sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
        )
        let models = (try? modelContext.fetch(descriptor)) ?? []
        return models.map {
            NewsArticle(id: $0.id, title: $0.title, summary: $0.summary, url: $0.url, publishedAt: $0.publishedAt)
        }
    }
}
