import Combine
import CryptoCoreKit
import NavigationKit

@MainActor
public final class NewsListViewModel: ObservableObject {
    @Published public var articles: [NewsArticle] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let service: NewsServicing

    public init(service: NewsServicing) {
        self.service = service
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            articles = try await service.articles()
        } catch {
            errorMessage = "\(error)"
        }
    }
}
