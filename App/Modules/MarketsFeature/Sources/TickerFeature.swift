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
        // Parent (MarketsFeature) owns which symbols this session watches;
        // the default keeps `TickerFeature.State()` working for tests that
        // don't care about the list.
        public var watchedSymbols: [String] = ["btcusdt", "ethusdt", "solusdt"]

        public init(watchedSymbols: [String] = ["btcusdt", "ethusdt", "solusdt"]) {
            self.watchedSymbols = watchedSymbols
        }
    }

    public enum Action {
        case startTapped
        case stopTapped
        // Replaces a one-Action-per-tick design: TickerStream coalesces
        // however many ticks arrive within a ~100ms window into a single
        // Action carrying only each symbol's latest price, so a burst of
        // updates costs one Reduce call (one State mutation, one SwiftUI
        // diff pass) instead of one per tick.
        case priceBatchUpdate(prices: [String: Double])
        case streamError(String)
    }

    private enum CancelID { case streaming }

    @Dependency(\.tickerClient) var tickerClient

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
                let symbols = state.watchedSymbols
                return .run { [tickerClient] send in
                    await TickerStream.run(symbols: symbols, tickerClient: tickerClient, send: send)
                }
                .cancellable(id: CancelID.streaming, cancelInFlight: true)

            case .stopTapped:
                state.isStreaming = false
                return .cancel(id: CancelID.streaming)

            case let .priceBatchUpdate(prices):
                for (coinId, usdPrice) in prices {
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
                }
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
//
// Port fallback: some networks block Binance's documented streaming port
// (9443) while leaving 443 open (the standard HTTPS port, which serves the
// same stream). 443 is tried first; if no event arrives within
// `connectTimeout`, that attempt is abandoned and 9443 is tried next. This
// is a client-side policy decision, not something the Rust core needs to
// know about - PriceTicker just connects to whatever port it's given.
private enum TickerStream {
    private static let ports: [UInt16] = [443, 9443]
    private static let connectTimeout: Duration = .seconds(5)
    private static let maxCycles = 5
    private static let initialBackoff: Duration = .seconds(1)

    static func run(symbols: [String], tickerClient: any TickerClientProtocol, send: Send<TickerFeature.Action>) async {
        var backoff = initialBackoff

        for cycle in 0..<maxCycles {
            var lastFailureReason = "unknown error"
            for port in ports {
                switch await attempt(symbols: symbols, port: port, tickerClient: tickerClient, send: send) {
                case .ranUntilCancelled:
                    return
                case let .failed(reason):
                    lastFailureReason = reason
                }
            }

            // Don't surface a spurious "couldn't connect" error, or sleep
            // before a retry, if we're only here because the user tapped
            // Stop mid-attempt.
            guard !Task.isCancelled else { return }

            let isLastCycle = cycle == maxCycles - 1
            if isLastCycle {
                let triedPorts = ports.map(String.init).joined(separator: ", ")
                await send(.streamError(
                    "Could not connect after \(maxCycles) attempts on any port (\(triedPorts)): \(lastFailureReason)"
                ))
                return
            }

            // Exponential backoff between full cycles: 1s, 2s, 4s, 8s -
            // both ports failing usually means a transient network issue,
            // not a permanently dead endpoint, so it's worth spacing
            // retries out rather than hammering both ports back-to-back.
            try? await Task.sleep(for: backoff)
            backoff *= 2
        }
    }

    private enum AttemptOutcome {
        // Received at least one real price update; ran until the caller
        // cancelled it (stop tapped) - the overall stream is done, no
        // fallback needed.
        case ranUntilCancelled
        // Never received a real update on this port - either it errored
        // out (e.g. connection refused) or timed out. Caller should try
        // the next port.
        case failed(String)
    }

    // Runs one connection attempt. Only an actual price update counts as
    // "this port works" - an error or a silent timeout both mean "try the
    // next port," not "surface this as the final failure."
    private static func attempt(
        symbols: [String],
        port: UInt16,
        tickerClient: any TickerClientProtocol,
        send: Send<TickerFeature.Action>
    ) async -> AttemptOutcome {
        let buffer = TickBuffer()
        let progress = ConnectionProgress()

        let stream = AsyncStream<TickerFeature.Action> { continuation in
            let listener = Listener(buffer, continuation)

            do {
                let ticker = try tickerClient.makeTicker(symbols, port: port, listener)

                // Flushes at most 10 times/sec regardless of tick rate: a
                // burst of ticks between flushes collapses into the one
                // snapshot draining sees, instead of one Action per tick.
                let flushTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(100))
                        let batch = await buffer.drain()
                        if !batch.isEmpty {
                            continuation.yield(.priceBatchUpdate(prices: batch))
                        }
                    }
                }

                continuation.onTermination = { [listener] _ in
                    _ = listener
                    flushTask.cancel()
                    // If Rust's connect() is still blocked (e.g. a
                    // firewalled port that hangs rather than refusing),
                    // this thread isn't forcibly killed - it just checks
                    // this flag and exits cleanly once connect eventually
                    // returns, instead of continuing to stream data nobody
                    // is listening for anymore.
                    ticker.stop()
                }
            } catch {
                continuation.yield(.streamError("\(error)"))
                continuation.finish()
            }
        }

        return await withTaskGroup(of: AttemptOutcome?.self) { group in
            group.addTask {
                for await action in stream {
                    switch action {
                    case .priceBatchUpdate:
                        await progress.markConnected()
                        await send(action)
                    case let .streamError(message):
                        if await progress.hasConnected {
                            // Was already streaming real data - this is a
                            // genuine mid-stream failure, not "port
                            // doesn't work." Surface it like before.
                            await send(action)
                        } else {
                            return .failed(message)
                        }
                    default:
                        break
                    }
                }
                return await progress.hasConnected ? .ranUntilCancelled : .failed("stream ended with no data")
            }
            group.addTask {
                try? await Task.sleep(for: connectTimeout)
                return await progress.hasConnected ? nil : .failed("timed out after \(connectTimeout)")
            }

            // Whichever finishes first with a non-nil result decides the
            // outcome; `nil` means "the timeout fired but we'd already
            // connected by then" - keep waiting on the real consumer.
            var outcome: AttemptOutcome?
            while let result = await group.next() {
                if let result {
                    outcome = result
                    break
                }
            }
            group.cancelAll()
            // Drain the loser so its cancellation (and AsyncStream's
            // onTermination -> ticker.stop()) has actually run before this
            // function returns and the caller possibly tries another port.
            for await _ in group {}
            return outcome ?? .failed("cancelled")
        }
    }

    // Coalesces same-symbol ticks that land within one flush window down
    // to "latest price wins" - an actor so concurrent writes from
    // Listener's spawned Tasks can't race each other.
    private actor TickBuffer {
        private var pending: [String: Double] = [:]

        func record(coinId: String, usdPrice: Double) {
            pending[coinId] = usdPrice
        }

        func drain() -> [String: Double] {
            defer { pending = [:] }
            return pending
        }
    }

    // Tracks whether this attempt has seen any real event yet, so the
    // timeout task and the consuming task can agree on the outcome
    // regardless of which one finishes first.
    private actor ConnectionProgress {
        private(set) var hasConnected = false
        func markConnected() { hasConnected = true }
    }

    private final class Listener: TickerListener {
        let buffer: TickBuffer
        let continuation: AsyncStream<TickerFeature.Action>.Continuation

        init(_ buffer: TickBuffer, _ continuation: AsyncStream<TickerFeature.Action>.Continuation) {
            self.buffer = buffer
            self.continuation = continuation
        }

        func onUpdate(ticker: PriceInfo) {
            // Called synchronously by Rust from its own thread - hop onto
            // the buffer's actor rather than blocking that thread.
            Task { await buffer.record(coinId: ticker.coinId, usdPrice: ticker.usdPrice) }
        }

        func onError(message: String) {
            continuation.yield(.streamError(message))
        }
    }
}
