import SwiftUI
import CryptoCoreKit

@MainActor
public final class AsyncPriceViewModel: ObservableObject {
    // Separate state per section: these are two independent demos (a real
    // price fetch vs. deliberately triggering a validation error) sharing
    // one loading/result flag would tie their buttons together — tapping
    // one would disable and overwrite the other.
    @Published public var priceResult: String?
    @Published public var priceErrorDetail: String?
    @Published public var isPriceLoading = false

    @Published public var errorDemoResult: String?
    @Published public var errorDemoDetail: String?
    @Published public var isErrorDemoLoading = false

    public init() {}

    public func fetchPrice(coinId: String) {
        isPriceLoading = true
        priceErrorDetail = nil
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
                priceErrorDetail = detail(for: error)
            } catch {
                priceResult = nil
                priceErrorDetail = "\(error)"
            }
            isPriceLoading = false
        }
    }

    public func triggerErrorDemo(coinId: String) {
        isErrorDemoLoading = true
        errorDemoDetail = nil
        Task {
            do {
                let info = try await getPriceAsync(coinId: coinId)
                errorDemoResult = formatted(info.usdPrice)
            } catch let error as PriceError {
                errorDemoResult = nil
                errorDemoDetail = detail(for: error)
            } catch {
                errorDemoResult = nil
                errorDemoDetail = "\(error)"
            }
            isErrorDemoLoading = false
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

public struct AsyncDemoView: View {
    @ObservedObject public var viewModel: AsyncPriceViewModel

    public init(viewModel: AsyncPriceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
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

                resultCard(result: viewModel.priceResult, errorDetail: viewModel.priceErrorDetail)

                Button("Get ETH price") {
                    viewModel.fetchPrice(coinId: "ethereum")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isPriceLoading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ERROR HANDLING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                resultCard(result: viewModel.errorDemoResult, errorDetail: viewModel.errorDemoDetail)

                Button("Trigger invalid coin") {
                    viewModel.triggerErrorDemo(coinId: "this-coin-does-not-exist")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isErrorDemoLoading)
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func resultCard(result: String?, errorDetail: String?) -> some View {
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
                Text(result ?? "—")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
