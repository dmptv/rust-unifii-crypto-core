import SwiftUI

@MainActor
final class TickerViewModel: ObservableObject {
    @Published var prices: [String: Double] = [:]
    @Published var errorMessage: String?
    @Published var isStreaming = false

    private var ticker: PriceTicker?
    private var listener: BinanceListener?

    func start(symbols: [String]) {
        guard !isStreaming else { return }
        errorMessage = nil

        let listener = BinanceListener(viewModel: self)
        self.listener = listener
        ticker = PriceTicker(symbols: symbols, listener: listener)
        isStreaming = true
    }

    func stop() {
        ticker?.stop()
        ticker = nil
        listener = nil
        isStreaming = false
    }

    fileprivate func handleUpdate(_ info: PriceInfo) {
        prices[info.coinId] = info.usdPrice
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
                .fill(isActive ? Color.green : Color.secondary)
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
                .foregroundStyle(.secondary)
        }
        .onAppear { pulse = isActive }
        .onChange(of: isActive) { _, newValue in pulse = newValue }
    }
}

private struct PriceRowView: View {
    let symbol: String
    let price: Double?

    @State private var flashColor: Color = .clear

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(coinColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(symbol.prefix(1)))
                        .font(.subheadline.bold())
                        .foregroundStyle(coinColor)
                )

            Text(displayName)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Group {
                if let price {
                    Text(formatted(price))
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                } else {
                    Text("···")
                }
            }
            .foregroundStyle(flashColor == .clear ? Color.primary : flashColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        .onChange(of: price) { oldValue, newValue in
            guard let oldValue, let newValue, oldValue != newValue else { return }
            flashColor = newValue > oldValue ? .green : .red
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.easeOut(duration: 0.4)) {
                    flashColor = .clear
                }
            }
        }
    }

    private var displayName: String {
        symbol.replacingOccurrences(of: "USDT", with: "")
    }

    private var coinColor: Color {
        switch symbol {
        case "BTCUSDT": .orange
        case "ETHUSDT": .indigo
        case "SOLUSDT": .teal
        default: .gray
        }
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let body = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(body)"
    }
}

struct LiveDashboardView: View {
    @StateObject private var viewModel = TickerViewModel()
    private let symbols = ["btcusdt", "ethusdt", "solusdt"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Markets")
                        .font(.title2.bold())
                    Text("Live market data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(isActive: viewModel.isStreaming)
            }

            VStack(spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    PriceRowView(symbol: symbol.uppercased(), price: viewModel.prices[symbol.uppercased()])
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer(minLength: 12)

            Button(viewModel.isStreaming ? "Stop updates" : "Start updates") {
                if viewModel.isStreaming {
                    viewModel.stop()
                } else {
                    viewModel.start(symbols: symbols)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(viewModel.isStreaming ? .red : .accentColor)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .padding()
    }
}
