import NavigationKit
import Swinject

public final class WatchlistAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        container.register(WatchlistServicing.self) { _ in
            RustWatchlistService()
        }
    }
}
