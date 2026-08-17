import ComposableArchitecture
import CryptoCoreKit

@Reducer
public struct CoinListFeature {
    @ObservableState
    public struct State: Equatable {
        public var coins: [CoinListing] = []
        public var isLoadingInitial = false
        public var isLoadingMore = false
        public var errorMessage: String?

        // Opaque, per getCoinsPage(cursor:) — this reducer never inspects
        // it, only stores whatever the last page handed back.
        var nextCursor: String?
        var hasLoadedOnce = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case refresh
        case loadMoreIfNeeded(CoinListing)
        case pageResponse(isInitial: Bool, Result<CoinsPage, CoinListFetchError>)
        case coinTapped(String)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoadedOnce else { return .none }
                return refresh(&state)

            case .refresh:
                return refresh(&state)

            case let .loadMoreIfNeeded(coin):
                guard !state.isLoadingMore, !state.isLoadingInitial,
                      let cursor = state.nextCursor,
                      let index = state.coins.firstIndex(where: { $0.coinId == coin.coinId }) else {
                    return .none
                }
                // Fetch the next page once the user scrolls near the end
                // rather than waiting for the very last row, so the list
                // doesn't stall while the network call is in flight.
                let thresholdIndex = state.coins.index(
                    state.coins.endIndex, offsetBy: -5, limitedBy: state.coins.startIndex
                ) ?? state.coins.startIndex
                guard index >= thresholdIndex else { return .none }

                state.isLoadingMore = true
                return .run { send in
                    await send(.pageResponse(isInitial: false, Self.fetchPage(cursor: cursor)))
                }

            case let .pageResponse(isInitial, result):
                if isInitial {
                    state.isLoadingInitial = false
                } else {
                    state.isLoadingMore = false
                }
                switch result {
                case let .success(page):
                    if isInitial {
                        state.coins = page.coins
                    } else {
                        state.coins.append(contentsOf: page.coins)
                    }
                    state.nextCursor = page.nextCursor
                    state.hasLoadedOnce = true
                case let .failure(error):
                    // Leave existing coins and cursor in place so the next
                    // scroll (or a pull-to-refresh) can retry instead of
                    // losing progress.
                    state.errorMessage = error.message
                }
                return .none

            case .coinTapped:
                // Handled by the parent MarketsFeature reducer via the
                // .path case, which pushes CoinDetailFeature.
                return .none
            }
        }
    }

    private func refresh(_ state: inout State) -> Effect<Action> {
        state.isLoadingInitial = true
        state.errorMessage = nil
        return .run { send in
            await send(.pageResponse(isInitial: true, Self.fetchPage(cursor: nil)))
        }
    }

    private static func fetchPage(cursor: String?) async -> Result<CoinsPage, CoinListFetchError> {
        do {
            let page = try await Task.detached(priority: .userInitiated) {
                try getCoinsPage(cursor: cursor)
            }.value
            return .success(page)
        } catch {
            return .failure(CoinListFetchError(message: "\(error)"))
        }
    }
}

public struct CoinListFetchError: Error, Equatable, Sendable {
    public let message: String
}
