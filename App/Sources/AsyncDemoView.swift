import SwiftUI

struct AsyncDemoView: View {
    @State private var priceResult: String?
    @State private var errorDetail: String?
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Async")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Swift async/await over UniFFI")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Divider().overlay(Color.white.opacity(0.15))

            VStack(alignment: .leading, spacing: 10) {
                Text("ETH PRICE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                resultCard

                Button("Get ETH price") {
                    fetchPriceAsync(coinId: "ethereum")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ERROR HANDLING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                Button("Trigger invalid coin") {
                    fetchPriceAsync(coinId: "this-coin-does-not-exist")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private var resultCard: some View {
        Group {
            if let errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text(errorDetail)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                }
            } else {
                Text(priceResult ?? "—")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func fetchPriceAsync(coinId: String) {
        isLoading = true
        errorDetail = nil
        // No Task.detached / MainActor.run needed here, unlike the sync
        // getPrice() call on the Live tab: this Task already runs on the
        // main actor, and `await` suspends it without blocking a thread —
        // that suspend/resume machinery is exactly what UniFFI's async
        // export generates on both the Rust and Swift sides.
        Task {
            do {
                let info = try await getPriceAsync(coinId: coinId)
                priceResult = formatted(info.usdPrice)
            } catch let error as PriceError {
                priceResult = nil
                errorDetail = detail(for: error)
            } catch {
                priceResult = nil
                errorDetail = "\(error)"
            }
            isLoading = false
        }
    }

    private func detail(for error: PriceError) -> String {
        switch error {
        case .RateLimited:
            "Rate limited — try again shortly"
        case let .Network(reason):
            reason
        case .InvalidResponse:
            "Invalid coin"
        case let .InvalidInput(reason):
            reason
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
