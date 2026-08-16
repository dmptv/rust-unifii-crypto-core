import Combine
import CryptoCoreKit
import NavigationKit

@MainActor
public final class CoinDetailViewModel: ObservableObject {
    @Published public var details: CoinDetails?
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    public let coinId: String
    private let service: MarketsServicing

    public init(coinId: String, service: MarketsServicing) {
        self.coinId = coinId
        self.service = service
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            details = try await service.coinDetails(coinId: coinId)
        } catch {
            errorMessage = "\(error)"
        }
    }
}
