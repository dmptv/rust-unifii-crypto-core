import CryptoCoreKit

public protocol NewsServicing {
    func articles() async throws -> [NewsArticle]
}
