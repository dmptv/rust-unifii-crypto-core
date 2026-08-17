import ComposableArchitecture
import CryptoCoreKit
import Foundation

// TCA pilot: unidirectional data flow instead of an ObservableObject with
// imperative methods. Two independent sections (a real price fetch vs.
// deliberately triggering a validation error) get their own state slices —
// same reasoning as before (shared state ties their buttons together), just
// expressed as State fields + Action cases instead of separate @Published
// trios.
@Reducer
public struct AsyncPriceFeature {
    @ObservableState
    public struct State: Equatable {
        public var priceResult: String?
        public var priceErrorDetail: String?
        public var isPriceLoading = false

        public var errorDemoResult: String?
        public var errorDemoDetail: String?
        public var isErrorDemoLoading = false

        public init() {}
    }

    public enum Action {
        case fetchPriceTapped
        case triggerErrorDemoTapped
        case priceResponse(Result<Double, PriceFetchError>)
        case errorDemoResponse(Result<Double, PriceFetchError>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPriceTapped:
                state.isPriceLoading = true
                state.priceErrorDetail = nil
                return .run { send in
                    await send(.priceResponse(Self.fetchPrice(coinId: "ethereum")))
                }

            case let .priceResponse(result):
                state.isPriceLoading = false
                switch result {
                case let .success(value):
                    state.priceResult = Self.formatted(value)
                case let .failure(error):
                    state.priceResult = nil
                    state.priceErrorDetail = error.message
                }
                return .none

            case .triggerErrorDemoTapped:
                state.isErrorDemoLoading = true
                state.errorDemoDetail = nil
                return .run { send in
                    await send(.errorDemoResponse(Self.fetchPrice(coinId: "this-coin-does-not-exist")))
                }

            case let .errorDemoResponse(result):
                state.isErrorDemoLoading = false
                switch result {
                case let .success(value):
                    state.errorDemoResult = Self.formatted(value)
                case let .failure(error):
                    state.errorDemoResult = nil
                    state.errorDemoDetail = error.message
                }
                return .none
            }
        }
    }

    // No Task.detached / MainActor.run needed here, unlike the sync
    // getPrice() call on the Live tab: this Effect already runs off the
    // main actor, and `await` suspends it without blocking a thread — that
    // suspend/resume machinery is exactly what UniFFI's async export
    // generates on both the Rust and Swift sides.
    private static func fetchPrice(coinId: String) async -> Result<Double, PriceFetchError> {
        do {
            let info = try await getPriceAsync(coinId: coinId)
            return .success(info.usdPrice)
        } catch let error as PriceError {
            return .failure(PriceFetchError(message: detail(for: error)))
        } catch {
            return .failure(PriceFetchError(message: "\(error)"))
        }
    }

    private static func detail(for error: PriceError) -> String {
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

    private static func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let body = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(body)"
    }
}

// Result's Failure must be Error; PriceError itself (the raw UniFFI error)
// isn't guaranteed Equatable/Sendable, so it's flattened to a message here -
// Action needs to carry a value TCA can compare in tests.
public struct PriceFetchError: Error, Equatable, Sendable {
    public let message: String
}
