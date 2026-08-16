import CryptoCoreKit
import NavigationKit

// getCoinDetails is a synchronous, network-calling FFI function; hop off
// the caller's thread so MarketsServicing.coinDetails can be awaited safely
// from the main actor.
public final class RustMarketsService: MarketsServicing {
    public init() {}

    public func coinDetails(coinId: String) async throws -> CoinDetails {
        try await Task.detached(priority: .userInitiated) {
            try getCoinDetails(coinId: coinId)
        }.value
    }

    public func coinsPage(cursor: String?) async throws -> CoinsPage {
        try await Task.detached(priority: .userInitiated) {
            try getCoinsPage(cursor: cursor)
        }.value
    }
}
