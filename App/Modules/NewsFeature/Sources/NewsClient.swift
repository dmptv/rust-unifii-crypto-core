import ComposableArchitecture
import CryptoCoreKit
import Dependencies
import Foundation
import SwiftData

// TCA's replacement for what Swinject/NewsAssembly used to wire up:
// @Dependency instead of a Container. getNews is a synchronous,
// network-calling FFI function (fetches and parses CoinDesk's RSS feed);
// hop off the caller's thread the same way MarketsFeature does for
// getCoinDetails.
//
// Offline-first: a successful fetch refreshes a local SwiftData cache of
// the last-seen articles; a failed fetch (no network) falls back to
// whatever's cached instead of leaving the screen empty.
public struct NewsClient: Sendable {
    public var articles: @Sendable () async throws -> [NewsArticle]
}

extension NewsClient: DependencyKey {
    public static let liveValue: NewsClient = {
        // Store's init touches ModelContainer.mainContext, which is
        // @MainActor-isolated; liveValue's own initializer isn't, so this
        // asserts what's true at runtime (first access happens on the main
        // actor) rather than threading @MainActor through DependencyKey.
        let store = MainActor.assumeIsolated { Store() }
        return NewsClient(articles: { try await store.articles() })
    }()
}

extension DependencyValues {
    public var newsClient: NewsClient {
        get { self[NewsClient.self] }
        set { self[NewsClient.self] = newValue }
    }
}

// ModelContext's Sendable conformance is unavailable, so it can only ever
// be touched from a single isolation domain - this class is pinned to the
// main actor for that reason. @unchecked Sendable is safe here because
// isolation, not the annotation, is what actually protects modelContext;
// the annotation only lets `store` be captured by the @Sendable closure
// above.
@MainActor
private final class Store: @unchecked Sendable {
    private let modelContext: ModelContext

    init() {
        let schema = Schema([CachedNewsArticleModel.self])
        do {
            let container = try ModelContainer(for: schema)
            self.modelContext = container.mainContext
        } catch {
            fatalError("Failed to create SwiftData ModelContainer for News: \(error)")
        }
    }

    func articles() async throws -> [NewsArticle] {
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
