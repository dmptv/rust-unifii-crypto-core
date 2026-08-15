import SwiftUI

struct AsyncDemoView: View {
    @State private var priceResult: String?
    @State private var errorDetail: String?
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Async")
                    .font(.title2.bold())
                Text("Swift async/await over UniFFI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ETH price")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                resultCard

                Button("Get ETH price") {
                    fetchPriceAsync(coinId: "ethereum")
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Error handling")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button("Trigger invalid coin") {
                    fetchPriceAsync(coinId: "this-coin-does-not-exist")
                }
                .buttonStyle(.glass)
                .tint(.orange)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
    }

    @ViewBuilder
    private var resultCard: some View {
        Group {
            if let errorDetail {
                VStack(spacing: 4) {
                    Text("Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(errorDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text(priceResult ?? "—")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
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
