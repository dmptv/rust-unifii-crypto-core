import NavigationKit
import SwiftData
import Swinject

public final class WatchlistAssembly: Assembly {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public func assemble(container: Container) {
        container.register(WatchlistServicing.self) { [modelContainer] _ in
            // Resolution always happens from MainActor-isolated coordinator
            // init, but Swinject's registration closure itself isn't
            // statically MainActor — assumeIsolated asserts what's already
            // true at runtime rather than threading @MainActor through
            // Swinject's API.
            RustWatchlistService(modelContext: MainActor.assumeIsolated { modelContainer.mainContext })
        }
    }
}
