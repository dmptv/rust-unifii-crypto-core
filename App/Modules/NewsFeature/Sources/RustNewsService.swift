import CryptoCoreKit
import NavigationKit

// getNews is a synchronous, network-calling FFI function (it fetches and
// parses CoinDesk's RSS feed); hop off the caller's thread the same way
// RustMarketsService does for getCoinDetails.
public final class RustNewsService: NewsServicing {
    public init() {}

    public func articles() async throws -> [NewsArticle] {
        try await Task.detached(priority: .userInitiated) {
            try getNews()
        }.value
    }
}
