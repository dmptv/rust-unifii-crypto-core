import ComposableArchitecture

// Terminal screen of the Markets flow — no service call, so nothing beyond
// the coinId lives in State; the "notify me" toggle stays as local View
// @State (trivial UI state, not business logic). Still needs to be a
// Reducer since every case of MarketsFeature.Path must be one.
@Reducer
public struct PriceAlertFeature {
    @ObservableState
    public struct State: Equatable {
        public let coinId: String

        public init(coinId: String) {
            self.coinId = coinId
        }
    }

    public enum Action {}

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
