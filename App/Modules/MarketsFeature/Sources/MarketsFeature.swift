import ComposableArchitecture

// Push-onto-current-stack scenario: a deep link into CoinDetail (optionally
// continuing to PriceAlerts) is appended to whatever's already on the
// Markets tab's StackState rather than replacing it or presenting a new
// one. StackState/StackAction replace the old MarketsCoordinator's
// NavigationPath + MarketsRoute enum - the tree of possible destinations is
// now the Path reducer below instead of a hand-written enum.
@Reducer
public struct MarketsFeature {
    @ObservableState
    public struct State: Equatable {
        public var ticker = TickerFeature.State()
        public var path = StackState<Path.State>()

        public init() {}
    }

    public enum Action {
        case ticker(TickerFeature.Action)
        case path(StackActionOf<Path>)
        case coinSelected(String)
        case browseAllCoinsTapped
        // Deep-link entry point: mirrors NavigationKit's
        // CoinDetailDestination tree (coinId, then optionally a nested
        // PriceAlertDestination).
        case deepLinkToCoinDetail(coinId: String, thenPriceAlert: Bool)
    }

    @Reducer(state: .equatable)
    public enum Path {
        case coinDetail(CoinDetailFeature)
        case priceAlert(PriceAlertFeature)
        case coinList(CoinListFeature)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.ticker, action: \.ticker) {
            TickerFeature()
        }

        Reduce { state, action in
            switch action {
            case let .coinSelected(coinId):
                state.path.append(.coinDetail(CoinDetailFeature.State(coinId: coinId)))
                return .none

            case .browseAllCoinsTapped:
                state.path.append(.coinList(CoinListFeature.State()))
                return .none

            case let .deepLinkToCoinDetail(coinId, thenPriceAlert):
                state.path.append(.coinDetail(CoinDetailFeature.State(coinId: coinId)))
                if thenPriceAlert {
                    state.path.append(.priceAlert(PriceAlertFeature.State(coinId: coinId)))
                }
                return .none

            case .path(.element(id: _, action: .coinDetail(.setAlertTapped))):
                guard let last = state.path.last, case let .coinDetail(coinDetailState) = last else {
                    return .none
                }
                state.path.append(.priceAlert(PriceAlertFeature.State(coinId: coinDetailState.coinId)))
                return .none

            case let .path(.element(id: _, action: .coinList(.coinTapped(coinId)))):
                state.path.append(.coinDetail(CoinDetailFeature.State(coinId: coinId)))
                return .none

            case .path, .ticker:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
