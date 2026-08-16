import Foundation
import SwiftData

@Model
public final class WatchlistedCoinModel {
    @Attribute(.unique) public var coinId: String
    public var coinName: String
    public var addedAt: Date

    public init(coinId: String, coinName: String, addedAt: Date = .now) {
        self.coinId = coinId
        self.coinName = coinName
        self.addedAt = addedAt
    }
}
