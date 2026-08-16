import Foundation
import SwiftData

@Model
public final class CachedNewsArticleModel {
    @Attribute(.unique) public var id: String
    public var title: String
    public var summary: String
    public var url: String
    public var publishedAt: String
    public var cachedAt: Date

    public init(id: String, title: String, summary: String, url: String, publishedAt: String, cachedAt: Date = .now) {
        self.id = id
        self.title = title
        self.summary = summary
        self.url = url
        self.publishedAt = publishedAt
        self.cachedAt = cachedAt
    }
}
