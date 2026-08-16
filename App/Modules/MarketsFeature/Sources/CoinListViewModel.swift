import Combine
import CryptoCoreKit
import NavigationKit

@MainActor
public final class CoinListViewModel: ObservableObject {
    @Published public var coins: [CoinListing] = []
    @Published public var isLoadingInitial = false
    @Published public var isLoadingMore = false
    @Published public var errorMessage: String?

    // Opaque, per MarketsServicing.coinsPage — this view model never
    // inspects it, only stores whatever the last page handed back.
    private var nextCursor: String?
    private var hasLoadedOnce = false

    private let service: MarketsServicing

    public init(service: MarketsServicing) {
        self.service = service
    }

    public func loadInitialIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await refresh()
    }

    public func refresh() async {
        isLoadingInitial = true
        errorMessage = nil
        defer { isLoadingInitial = false }
        do {
            let page = try await service.coinsPage(cursor: nil)
            coins = page.coins
            nextCursor = page.nextCursor
            hasLoadedOnce = true
        } catch {
            errorMessage = "\(error)"
        }
    }

    public func loadMoreIfNeeded(currentItem: CoinListing) async {
        // Fetch the next page once the user scrolls near the end rather
        // than waiting for the very last row, so the list doesn't stall
        // while the network call is in flight.
        guard let index = coins.firstIndex(where: { $0.coinId == currentItem.coinId }) else { return }
        let thresholdIndex = coins.index(coins.endIndex, offsetBy: -5, limitedBy: coins.startIndex) ?? coins.startIndex
        guard index >= thresholdIndex else { return }
        await loadMore()
    }

    private func loadMore() async {
        guard !isLoadingMore, !isLoadingInitial, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.coinsPage(cursor: cursor)
            coins.append(contentsOf: page.coins)
            nextCursor = page.nextCursor
        } catch {
            // Leave existing coins and cursor in place so the next scroll
            // (or a pull-to-refresh) can retry instead of losing progress.
            errorMessage = "\(error)"
        }
    }
}
