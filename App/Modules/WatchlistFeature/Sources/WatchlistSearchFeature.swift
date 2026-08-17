import ComposableArchitecture
import CryptoCoreKit
import Foundation

public struct WatchlistFetchError: Error, Equatable, Sendable {
    public let message: String
    public init(_ error: Error) {
        self.message = String(describing: error)
    }
}

@Reducer
public struct WatchlistSearchFeature {
    @ObservableState
    public struct State: Equatable {
        public var query = ""
        public var results: [CoinSearchResult] = []
        public var isLoading = false
        public var errorMessage: String?

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchResponse(Result<[CoinSearchResult], WatchlistFetchError>)
        case coinTapped(coinId: String, coinName: String)
    }

    private enum CancelID { case search }

    @Dependency(\.watchlistClient) var watchlistClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else {
                    state.results = []
                    state.errorMessage = nil
                    return .cancel(id: CancelID.search)
                }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    await send(.searchResponse(Result { try await watchlistClient.searchCoins(query) }.mapError(WatchlistFetchError.init)))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .binding:
                return .none

            case let .searchResponse(.success(results)):
                state.isLoading = false
                state.results = results
                return .none

            case let .searchResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.message
                return .none

            case .coinTapped:
                return .none
            }
        }
    }
}
