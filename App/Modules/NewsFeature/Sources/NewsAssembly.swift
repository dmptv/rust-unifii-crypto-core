import NavigationKit
import Swinject

public final class NewsAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        container.register(NewsServicing.self) { _ in
            RustNewsService()
        }
    }
}
