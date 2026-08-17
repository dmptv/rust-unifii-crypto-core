import NewsFeature
import SwiftData
import Swinject
import WatchlistFeature

// Single composition root: aggregates every feature module's Assembly so
// coordinators can resolve their dependencies through one Container instead
// of each feature reaching into the others' concrete types.
enum AppContainer {
    // One SwiftData store for the whole app; each feature owns its own
    // @Model types (WatchlistedCoinModel, CachedNewsArticleModel) but they
    // share a container rather than each opening a separate store.
    static let modelContainer: ModelContainer = {
        let schema = Schema([WatchlistedCoinModel.self, CachedNewsArticleModel.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    static let shared: Resolver = Assembler(
        [
            NewsAssembly(modelContainer: modelContainer),
            WatchlistAssembly(modelContainer: modelContainer),
        ]
    ).resolver
}
