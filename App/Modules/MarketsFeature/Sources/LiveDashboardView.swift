import ComposableArchitecture
import SwiftUI

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
    let store: StoreOf<MarketsFeature>
    private let symbols = ["btcusdt", "ethusdt", "solusdt"]

    public init(store: StoreOf<MarketsFeature>) {
        self.store = store
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
                StatusPill(isActive: store.ticker.isStreaming)
            }
            .padding(.bottom, 12)

            Divider().overlay(Color.white.opacity(0.15))

            ForEach(symbols, id: \.self) { symbol in
                MarketRowView(
                    symbol: symbol.uppercased(),
                    price: store.ticker.prices[symbol.uppercased()],
                    history: store.ticker.history[symbol.uppercased()] ?? [],
                    baseline: store.ticker.baselines[symbol.uppercased()],
                    onTap: {
                        if let coinId = coinGeckoIds[symbol] {
                            store.send(.coinSelected(coinId))
                        }
                    }
                )
                Divider().overlay(Color.white.opacity(0.1))
            }

            if let error = store.ticker.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer(minLength: 12)

            Button(store.ticker.isStreaming ? "Stop updates" : "Start updates") {
                store.send(.ticker(store.ticker.isStreaming ? .stopTapped : .startTapped))
            }
            .buttonStyle(.borderedProminent)
            .tint(store.ticker.isStreaming ? .red : .blue)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .padding()
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
        .toolbar {
            // A toolbar item, not an inline button: this is the standard
            // iOS signal for "navigates elsewhere" (compare Mail's compose
            // icon), keeping it visually distinct from Start/Stop updates,
            // which acts on this screen's own WebSocket connection.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.browseAllCoinsTapped)
                } label: {
                    Label("Browse all coins", systemImage: "list.bullet")
                }
            }
        }
    }
}
