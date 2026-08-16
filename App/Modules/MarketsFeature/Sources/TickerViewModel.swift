import Combine
import CryptoCoreKit

@MainActor
public final class TickerViewModel: ObservableObject {
    @Published public var prices: [String: Double] = [:]
    @Published public var history: [String: [Double]] = [:]
    @Published public var baselines: [String: Double] = [:]
    @Published public var errorMessage: String?
    @Published public var isStreaming = false

    private var ticker: PriceTicker?
    private var listener: BinanceListener?

    public init() {}

    public func start(symbols: [String]) {
        guard !isStreaming else { return }
        errorMessage = nil
        prices = [:]
        history = [:]
        baselines = [:]

        let listener = BinanceListener(viewModel: self)
        self.listener = listener

        // PriceTicker's constructor now validates `symbols` on the Rust side
        // and throws PriceError.InvalidInput for anything outside
        // [a-zA-Z0-9-] — the FFI boundary doesn't trust whatever Swift sends it.
        do {
            ticker = try PriceTicker(symbols: symbols, listener: listener)
            isStreaming = true
        } catch {
            self.listener = nil
            errorMessage = "\(error)"
        }
    }

    public func stop() {
        ticker?.stop()
        ticker = nil
        listener = nil
        isStreaming = false
    }

    fileprivate func handleUpdate(_ info: PriceInfo) {
        if baselines[info.coinId] == nil {
            baselines[info.coinId] = info.usdPrice
        }
        prices[info.coinId] = info.usdPrice

        var buffer = history[info.coinId] ?? []
        buffer.append(info.usdPrice)
        if buffer.count > 40 {
            buffer.removeFirst(buffer.count - 40)
        }
        history[info.coinId] = buffer
    }

    fileprivate func handleError(_ message: String) {
        errorMessage = message
        isStreaming = false
    }
}

// TickerListener's methods are called by Rust from its own background
// thread, so every call here hops back to the main actor before touching
// any @Published state.
private final class BinanceListener: TickerListener {
    weak var viewModel: TickerViewModel?

    init(viewModel: TickerViewModel) {
        self.viewModel = viewModel
    }

    func onUpdate(ticker: PriceInfo) {
        Task { @MainActor in
            viewModel?.handleUpdate(ticker)
        }
    }

    func onError(message: String) {
        Task { @MainActor in
            viewModel?.handleError(message)
        }
    }
}
