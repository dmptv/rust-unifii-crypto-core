import SwiftUI
import NavigationKit
import Swinject

// Modal-with-X scenario: the entire News flow lives inside one sheet with
// its own NavigationStack. A deep link either opens straight to the list or
// pushes directly to an article; either way the sheet itself is presented,
// since there's no "current stack" to push onto here.
@MainActor
public final class NewsCoordinator: ObservableObject {
    @Published public var isPresented = false
    @Published public var path = NavigationPath()

    // Owned for the coordinator's lifetime rather than recreated in `body`:
    // NewsCoordinatorView reads this as a stored property so the list's
    // loaded state survives re-renders triggered by unrelated @Published
    // changes (isPresented, path).
    public let newsListViewModel: NewsListViewModel

    private let container: Resolver

    public init(container: Resolver) {
        self.container = container
        self.newsListViewModel = NewsListViewModel(service: container.resolve(NewsServicing.self)!)
    }

    public func handle(_ destination: NewsDestination) {
        isPresented = true
        switch destination {
        case .list:
            path = NavigationPath()
        case .articleDetail(let articleId):
            path = NavigationPath()
            path.append(NewsRoute.articleDetail(articleId: articleId))
        }
    }

    public func dismiss() {
        isPresented = false
        path = NavigationPath()
    }

    public func makeArticleDetailViewModel(articleId: String) -> NewsArticleDetailViewModel {
        NewsArticleDetailViewModel(articleId: articleId, service: container.resolve(NewsServicing.self)!)
    }
}
