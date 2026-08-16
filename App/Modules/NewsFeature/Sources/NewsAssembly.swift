import NavigationKit
import SwiftData
import Swinject

public final class NewsAssembly: Assembly {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public func assemble(container: Container) {
        container.register(NewsServicing.self) { [modelContainer] _ in
            // See WatchlistAssembly for why assumeIsolated is used here.
            RustNewsService(modelContext: MainActor.assumeIsolated { modelContainer.mainContext })
        }
    }
}
