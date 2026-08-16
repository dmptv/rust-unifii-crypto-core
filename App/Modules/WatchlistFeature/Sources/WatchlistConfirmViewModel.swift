import Combine
import NavigationKit

@MainActor
public final class WatchlistConfirmViewModel: ObservableObject {
    @Published public var isAdded = false

    public let coinId: String
    public let coinName: String
    private let service: WatchlistServicing

    public init(coinId: String, coinName: String, service: WatchlistServicing) {
        self.coinId = coinId
        self.coinName = coinName
        self.service = service
    }

    public func confirm() {
        service.add(WatchlistedCoin(coinId: coinId, coinName: coinName))
        isAdded = true
    }
}
