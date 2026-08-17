import ComposableArchitecture
import CryptoCoreKit

@Reducer
public struct CoinDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public let coinId: String
        public var details: CoinDetails?
        public var isLoading = false
        public var errorMessage: String?

        public init(coinId: String) {
            self.coinId = coinId
        }
    }

    public enum Action {
        case onAppear
        case detailsResponse(Result<CoinDetails, CoinDetailFetchError>)
        case setAlertTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.details == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let coinId = state.coinId
                return .run { send in
                    await send(.detailsResponse(Self.fetch(coinId: coinId)))
                }

            case let .detailsResponse(result):
                state.isLoading = false
                switch result {
                case let .success(details):
                    state.details = details
                case let .failure(error):
                    state.errorMessage = error.message
                }
                return .none

            case .setAlertTapped:
                // Handled by the parent MarketsFeature reducer, which
                // observes this action via the .path case and pushes
                // PriceAlertFeature - this reducer only owns its own screen.
                return .none
            }
        }
    }

    // getCoinDetails is a synchronous, network-calling FFI function; hop
    // off the caller's thread so this Effect doesn't block anything.
    private static func fetch(coinId: String) async -> Result<CoinDetails, CoinDetailFetchError> {
        do {
            let details = try await Task.detached(priority: .userInitiated) {
                try getCoinDetails(coinId: coinId)
            }.value
            return .success(details)
        } catch {
            return .failure(CoinDetailFetchError(message: "\(error)"))
        }
    }
}

public struct CoinDetailFetchError: Error, Equatable, Sendable {
    public let message: String
}
