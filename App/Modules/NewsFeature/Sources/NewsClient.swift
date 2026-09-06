import ComposableArchitecture
import CryptoCoreKit
import Dependencies
import DependencyContainerKit
import Foundation
import SwiftData

// getNews is a synchronous, network-calling FFI function (fetches and
// parses CoinDesk's RSS feed); hop off the caller's thread the same way
// MarketsFeature does for getCoinDetails.
//
// Offline-first: a successful fetch refreshes a local SwiftData cache of
// the last-seen articles; a failed fetch (no network) falls back to
// whatever's cached instead of leaving the screen empty.
public protocol NewsClientProtocol: Sendable {
    func articles() async throws -> [NewsArticle]
}

public final class LiveNewsClient: NewsClientProtocol, Sendable {
    private let store: Store

    private init(store: Store) {
        self.store = store
    }

    // Store's own actor initializer is nonisolated (safe to call from
    // anywhere - no other code can race it before `self` exists), so no
    // MainActor assumption is needed here at all.
    public static func live() -> LiveNewsClient {
        LiveNewsClient(store: Store())
    }

    public func articles() async throws -> [NewsArticle] {
        try await store.articles()
    }
}

private enum NewsClientKey: DependencyKey {
    // Point of glue: resolves whatever CryptoCoreApp registered into the
    // shared Swinject container at launch, rather than calling
    // LiveNewsClient.live() directly.
    static let liveValue: any NewsClientProtocol = AppDependencyContainer.shared.resolve(NewsClientProtocol.self)!
}

extension DependencyValues {
    public var newsClient: any NewsClientProtocol {
        get { self[NewsClientKey.self] }
        set { self[NewsClientKey.self] = newValue }
    }
}

// A plain actor rather than a @MainActor class: gives modelContext its own
// dedicated executor instead of MainActor's. On this Xcode 27 beta,
// touching a fresh ModelContext's fetch(_:) after a real async hop onto
// MainActor's executor reliably traps (EXC_BREAKPOINT) inside SwiftData -
// confirmed by bisection to be independent of *how* the hop happens
// (Task.detached, a plain continuation, MainActor.run, even
// MainActor.assumeIsolated once already inside a MainActor-dispatched
// call) and independent of "first fetch ever" (a synchronous warmup fetch
// in init(), with no prior await anywhere, succeeds reliably, twice in a
// row). Routing through a custom actor's executor instead of MainActor's
// sidesteps whatever is broken specifically in that pairing.
private actor Store {
    private let modelContext: ModelContext

    init() {
        // Core Data's own retry-on-missing-directory recovery is flaky on
        // this Xcode 27 beta simulator - don't depend on it. Guarantee the
        // directory exists ourselves before ModelContainer ever tries to
        // create the store file inside it.
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        let schema = Schema([CachedNewsArticleModel.self])
        // Named explicitly so this doesn't collide with WatchlistClient's
        // Store, which also creates a ModelContainer with no configured
        // URL - both would otherwise resolve to the same default.store
        // file with two incompatible schemas.
        let configuration = ModelConfiguration("NewsStore", schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            // Not container.mainContext - a fresh context confined to
            // this actor's own isolation domain instead of MainActor's.
            self.modelContext = ModelContext(container)
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
