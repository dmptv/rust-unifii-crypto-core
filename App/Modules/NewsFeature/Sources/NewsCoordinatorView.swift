import SwiftUI

public struct NewsCoordinatorView: View {
    @ObservedObject var coordinator: NewsCoordinator

    public init(coordinator: NewsCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            NewsListView(
                viewModel: coordinator.newsListViewModel,
                onSelect: { articleId in
                    coordinator.path.append(NewsRoute.articleDetail(articleId: articleId))
                },
                onClose: {
                    coordinator.dismiss()
                }
            )
            .navigationDestination(for: NewsRoute.self) { route in
                switch route {
                case .articleDetail(let articleId):
                    NewsArticleDetailView(viewModel: coordinator.makeArticleDetailViewModel(articleId: articleId))
                }
            }
        }
    }
}
