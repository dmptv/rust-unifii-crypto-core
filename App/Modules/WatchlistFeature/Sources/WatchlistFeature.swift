import ComposableArchitecture

@Reducer
public struct WatchlistFeature {
    @ObservableState
    public struct State: Equatable {
        public var search = WatchlistSearchFeature.State()
        public var path = StackState<Path.State>()

        public init() {}
    }

    public enum Action {
        case search(WatchlistSearchFeature.Action)
        case path(StackActionOf<Path>)
        case deepLinkToSearch
        case deepLinkToConfirm(coinId: String, coinName: String)
    }

    @Reducer(state: .equatable)
    public enum Path {
        case confirm(WatchlistConfirmFeature)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.search, action: \.search) { WatchlistSearchFeature() }
        Reduce { state, action in
            switch action {
            case let .search(.coinTapped(coinId, coinName)):
                state.path.append(.confirm(WatchlistConfirmFeature.State(coinId: coinId, coinName: coinName)))
                return .none

            case .search:
                return .none

            case .deepLinkToSearch:
                state.path.removeAll()
                return .none

            case let .deepLinkToConfirm(coinId, coinName):
                state.path.removeAll()
                state.path.append(.confirm(WatchlistConfirmFeature.State(coinId: coinId, coinName: coinName)))
                return .none

            case .path(.element(id: _, action: .confirm(.backTapped))):
                state.path.removeAll()
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
