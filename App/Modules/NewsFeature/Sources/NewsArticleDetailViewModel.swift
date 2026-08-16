import Combine
import CryptoCoreKit
import NavigationKit

// Resolves its own article by id rather than depending on NewsListViewModel
// already having loaded it, so a deep link straight to an article works
// exactly like tapping into one from the list.
@MainActor
public final class NewsArticleDetailViewModel: ObservableObject {
    @Published public var article: NewsArticle?
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    public let articleId: String
    private let service: NewsServicing

    public init(articleId: String, service: NewsServicing) {
        self.articleId = articleId
        self.service = service
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let all = try await service.articles()
            article = all.first { $0.id == articleId }
            if article == nil {
                errorMessage = "Article not found"
            }
        } catch {
            errorMessage = "\(error)"
        }
    }
}
