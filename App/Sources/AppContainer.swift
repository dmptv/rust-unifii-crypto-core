import MarketsFeature
import NewsFeature
import Swinject

// Single composition root: aggregates every feature module's Assembly so
// coordinators can resolve their dependencies through one Container instead
// of each feature reaching into the others' concrete types.
enum AppContainer {
    static let shared: Resolver = Assembler(
        [
            MarketsAssembly(),
            NewsAssembly(),
        ]
    ).resolver
}
