import ComposableArchitecture
import CryptoCoreKit
import Foundation

// Wraps getNews()'s throwing error into something Equatable/Sendable, the
// same way MarketsFeature wraps its FFI errors for use in TCA Actions.
public struct NewsFetchError: Error, Equatable, Sendable {
    public let message: String
    public init(_ error: Error) {
        self.message = String(describing: error)
    }
}

@Reducer
public struct NewsFeature {
    @ObservableState
    public struct State: Equatable {
        public var articles: [NewsArticle] = []
        public var isLoading = false
        public var errorMessage: String?
        public var path = StackState<Path.State>()

        public init() {}
    }

    public enum Action {
        case onAppear
        case articlesResponse(Result<[NewsArticle], NewsFetchError>)
        case articleTapped(String)
        case path(StackActionOf<Path>)
        case deepLinkToList
        case deepLinkToArticle(articleId: String)
    }

    @Reducer(state: .equatable)
    public enum Path {
        case articleDetail(NewsArticleDetailFeature)
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
                state.articles = articles
                return .none

            case let .articlesResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.message
                return .none

            case let .articleTapped(articleId):
                state.path.append(.articleDetail(NewsArticleDetailFeature.State(articleId: articleId)))
                return .none

            case .deepLinkToList:
                state.path.removeAll()
                return .none

            case let .deepLinkToArticle(articleId):
                state.path.removeAll()
                state.path.append(.articleDetail(NewsArticleDetailFeature.State(articleId: articleId)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
