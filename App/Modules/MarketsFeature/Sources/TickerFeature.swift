import ComposableArchitecture
import CryptoCoreKit

@Reducer
public struct TickerFeature {
    @ObservableState
    public struct State: Equatable {
        public var prices: [String: Double] = [:]
        public var history: [String: [Double]] = [:]
        public var baselines: [String: Double] = [:]
        public var errorMessage: String?
        public var isStreaming = false

        public init() {}
    }

    public enum Action {
        case startTapped
        case stopTapped
        case priceUpdate(coinId: String, usdPrice: Double)
        case streamError(String)
    }

    private enum CancelID { case streaming }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startTapped:
                guard !state.isStreaming else { return .none }
                state.errorMessage = nil
                state.prices = [:]
                state.history = [:]
                state.baselines = [:]
                state.isStreaming = true
                let symbols = ["btcusdt", "ethusdt", "solusdt"]
                return .run { send in
                    await TickerStream.run(symbols: symbols, send: send)
                }
                .cancellable(id: CancelID.streaming, cancelInFlight: true)

            case .stopTapped:
                state.isStreaming = false
                return .cancel(id: CancelID.streaming)

            case let .priceUpdate(coinId, usdPrice):
                if state.baselines[coinId] == nil {
                    state.baselines[coinId] = usdPrice
                }
                state.prices[coinId] = usdPrice

                var buffer = state.history[coinId] ?? []
                buffer.append(usdPrice)
                if buffer.count > 40 {
                    buffer.removeFirst(buffer.count - 40)
                }
                state.history[coinId] = buffer
                return .none

            case let .streamError(message):
                state.errorMessage = message
                state.isStreaming = false
                return .none
            }
        }
    }
}

// Bridges PriceTicker's callback-interface style API (TickerListener's
// methods are called by Rust from its own background thread) into an
// AsyncStream, so the reducer only ever sees plain Actions arriving through
// `send`. The ticker is stopped when the stream terminates - cancelling the
// owning Effect (via .cancellable) tears down the AsyncStream too.
private enum TickerStream {
    static func run(symbols: [String], send: Send<TickerFeature.Action>) async {
        let stream = AsyncStream<TickerFeature.Action> { continuation in
            let listener = Listener(continuation)
            do {
                let ticker = try PriceTicker(symbols: symbols, listener: listener)
                continuation.onTermination = { [listener] _ in
                    _ = listener
                    ticker.stop()
                }
            } catch {
                continuation.yield(.streamError("\(error)"))
                continuation.finish()
            }
        }
        for await action in stream {
            await send(action)
        }
    }

    private final class Listener: TickerListener {
        let continuation: AsyncStream<TickerFeature.Action>.Continuation

        init(_ continuation: AsyncStream<TickerFeature.Action>.Continuation) {
            self.continuation = continuation
        }

        func onUpdate(ticker: PriceInfo) {
            continuation.yield(.priceUpdate(coinId: ticker.coinId, usdPrice: ticker.usdPrice))
        }

        func onError(message: String) {
            continuation.yield(.streamError(message))
        }
    }
}
