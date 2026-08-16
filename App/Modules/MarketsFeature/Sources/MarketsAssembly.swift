import NavigationKit
import Swinject

// Registered into the app-wide Container at the composition root (see
// App/Sources/AppContainer.swift). Each feature module owns the wiring for
// its own protocols so the composition root only has to know the list of
// assemblies, not their internals.
public final class MarketsAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        container.register(MarketsServicing.self) { _ in
            RustMarketsService()
        }
    }
}
