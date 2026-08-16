import Combine
import CryptoCoreKit
import Foundation

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
