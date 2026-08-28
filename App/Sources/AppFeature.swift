import AsyncFeature
import ComposableArchitecture
import GrpcFeature
import MarketsFeature
import NavigationKit
import NewsFeature
import WatchlistFeature

enum AppTab: Hashable {
    case live, news, watchlist, async, grpc, push
}

// Single root reducer: every tab's feature lives here as child state, so a
// push notification can be routed with one action instead of a plain Swift
// class holding references to five separate stores.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        // Auth gate, shown on launch - whole-tree optional-destination
        // switch (@Presents/.ifLet), the one navigation pattern the rest
        // of the app doesn't otherwise use.
        @Presents var destination: Destination.State? = .auth(AuthFeature.State())
        var selectedTab: AppTab = .live
        var markets = MarketsFeature.State()
        var news = NewsFeature.State()
        var watchlist = WatchlistFeature.State()
        var async = AsyncPriceFeature.State()
        var grpc = GrpcFeature.State()
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case markets(MarketsFeature.Action)
        case news(NewsFeature.Action)
        case watchlist(WatchlistFeature.Action)
        case async(AsyncPriceFeature.Action)
        case grpc(GrpcFeature.Action)
        case deepLinkReceived(AppDestination)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case auth(AuthFeature)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.markets, action: \.markets) { MarketsFeature() }
        Scope(state: \.news, action: \.news) { NewsFeature() }
        Scope(state: \.watchlist, action: \.watchlist) { WatchlistFeature() }
        Scope(state: \.async, action: \.async) { AsyncPriceFeature() }
        Scope(state: \.grpc, action: \.grpc) { GrpcFeature() }
        Reduce { state, action in
            switch action {
            case .destination(.presented(.auth(.loginSuccess))):
                state.destination = nil
                return .none

            case let .deepLinkReceived(destination):
                switch destination {
                case .markets(let marketsDestination):
                    state.selectedTab = .live
                    switch marketsDestination {
                    case .coinDetail(.show(let coinId, let next)):
                        return .send(.markets(.deepLinkToCoinDetail(coinId: coinId, thenPriceAlert: next != nil)))
                    }

                case .news(let newsDestination):
                    state.selectedTab = .news
                    switch newsDestination {
                    case .list:
                        return .send(.news(.deepLinkToList))
                    case .articleDetail(let articleId):
                        return .send(.news(.deepLinkToArticle(articleId: articleId)))
                    }

                case .watchlist(let watchlistDestination):
                    state.selectedTab = .watchlist
                    switch watchlistDestination {
                    case .search:
                        return .send(.watchlist(.deepLinkToSearch))
                    case .confirm(let coinId, let coinName):
                        return .send(.watchlist(.deepLinkToConfirm(coinId: coinId, coinName: coinName)))
                    }
                }

            case .destination, .markets, .news, .watchlist, .async, .grpc, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
