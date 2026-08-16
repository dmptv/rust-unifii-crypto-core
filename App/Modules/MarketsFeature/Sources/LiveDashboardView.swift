import SwiftUI
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

private struct StatusPill: View {
    let isActive: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
                .scaleEffect(pulse ? 1.8 : 1.0)
                .opacity(pulse ? 0.3 : 1.0)
                .animation(
                    isActive
                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )
            Text(isActive ? "Streaming" : "Offline")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .onAppear { pulse = isActive }
        .onChange(of: isActive) { _, newValue in pulse = newValue }
    }
}

private struct MiniSparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            if values.count >= 2 {
                let minV = values.min() ?? 0
                let maxV = values.max() ?? 1
                let range = max(maxV - minV, 0.0001)

                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(values.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minV) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(trendColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 3]))
            }
        }
    }

    private var trendColor: Color {
        guard let first = values.first, let last = values.last else { return .gray }
        return last >= first ? .green : .red
    }
}

private struct MarketRowView: View {
    let symbol: String
    let price: Double?
    let history: [Double]
    let baseline: Double?
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(displayName)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)

                Spacer()

                MiniSparkline(values: history)
                    .frame(width: 64, height: 24)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let price {
                    Text(formattedPrice(price))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("—")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.25))
                }

                if let price, let baseline {
                    let delta = price - baseline
                    Text(deltaText(delta))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(delta >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var displayName: String {
        symbol.replacingOccurrences(of: "USDT", with: "")
    }

    private func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let body = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(body)"
    }

    private func deltaText(_ delta: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        let body = formatter.string(from: NSNumber(value: delta)) ?? String(format: "%.2f", delta)
        return body
    }
}

// CoinGecko ids for get_coin_details, keyed by the Binance symbols this
// dashboard already streams — kept here since this view is the only place
// that knows about both.
private let coinGeckoIds = [
    "btcusdt": "bitcoin",
    "ethusdt": "ethereum",
    "solusdt": "solana",
]

public struct LiveDashboardView: View {
    @ObservedObject public var viewModel: TickerViewModel
    private let symbols = ["btcusdt", "ethusdt", "solusdt"]
    private let onSelectCoin: (String) -> Void

    public init(viewModel: TickerViewModel, onSelectCoin: @escaping (String) -> Void = { _ in }) {
        self.viewModel = viewModel
        self.onSelectCoin = onSelectCoin
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Markets")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Live market data")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
                StatusPill(isActive: viewModel.isStreaming)
            }
            .padding(.bottom, 12)

            Divider().overlay(Color.white.opacity(0.15))

            ForEach(symbols, id: \.self) { symbol in
                MarketRowView(
                    symbol: symbol.uppercased(),
                    price: viewModel.prices[symbol.uppercased()],
                    history: viewModel.history[symbol.uppercased()] ?? [],
                    baseline: viewModel.baselines[symbol.uppercased()],
                    onTap: {
                        if let coinId = coinGeckoIds[symbol] {
                            onSelectCoin(coinId)
                        }
                    }
                )
                Divider().overlay(Color.white.opacity(0.1))
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer(minLength: 12)

            Button(viewModel.isStreaming ? "Stop updates" : "Start updates") {
                if viewModel.isStreaming {
                    viewModel.stop()
                } else {
                    viewModel.start(symbols: symbols)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isStreaming ? .red : .blue)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .padding()
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }
}
