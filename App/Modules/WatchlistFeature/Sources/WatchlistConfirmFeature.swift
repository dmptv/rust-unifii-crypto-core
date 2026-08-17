import ComposableArchitecture

@Reducer
public struct WatchlistConfirmFeature {
    @ObservableState
    public struct State: Equatable {
        public let coinId: String
        public let coinName: String
        public var isAdded = false

        public init(coinId: String, coinName: String) {
            self.coinId = coinId
            self.coinName = coinName
        }
    }

    public enum Action {
        case confirmTapped
        // Not handled here: the parent WatchlistFeature observes this and
        // clears its own path (rather than a plain stack pop) since a deep
        // link can land here directly, without Search ever being pushed.
        case backTapped
    }

    @Dependency(\.watchlistClient) var watchlistClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                let coin = WatchlistedCoin(coinId: state.coinId, coinName: state.coinName)
                state.isAdded = true
                return .run { _ in await watchlistClient.add(coin) }

            case .backTapped:
                return .none
            }
        }
    }
}
