import ComposableArchitecture
import CryptoCoreKit
import Foundation

@Reducer
public struct NewsArticleDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public let articleId: String
        public var article: NewsArticle?
        public var isLoading = false
        public var errorMessage: String?

        public init(articleId: String) {
            self.articleId = articleId
        }
    }

    public enum Action {
        case onAppear
        case articlesResponse(Result<[NewsArticle], NewsFetchError>)
    }

    @Dependency(\.newsClient) var newsClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    await send(.articlesResponse(Result { try await newsClient.articles() }.mapError(NewsFetchError.init)))
                }

            case let .articlesResponse(.success(articles)):
                state.isLoading = false
                state.article = articles.first { $0.id == state.articleId }
                return .none

            case let .articlesResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.message
                return .none
            }
        }
    }
}
