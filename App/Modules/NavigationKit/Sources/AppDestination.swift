import Foundation

// Deep-link payload contract: mirrors the coordinator hierarchy one-to-one.
// A push notification carries a JSON-encoded AppDestination; each level is
// decoded and delegated to the matching coordinator without presenting
// anything, until a case that carries its own display parameters is reached.
//
// Codable is hand-written rather than derived: the compiler's synthesized
// encoding for an enum's single *unlabeled* associated value emits a "_0"
// key, which is an implementation detail no backend team should have to
// know about to hand-write a push payload. Every level here instead uses
// the same explicit {"type": ..., "payload": ...} shape, so the whole tree
// has one predictable, human-writable JSON contract end to end.

public enum AppDestination: Codable, Sendable, Equatable {
    case markets(MarketsDestination)
    case news(NewsDestination)
    case watchlist(WatchlistDestination)

    private enum CodingKeys: String, CodingKey { case type, payload }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "markets":
            self = .markets(try container.decode(MarketsDestination.self, forKey: .payload))
        case "news":
            self = .news(try container.decode(NewsDestination.self, forKey: .payload))
        case "watchlist":
            self = .watchlist(try container.decode(WatchlistDestination.self, forKey: .payload))
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .markets(let destination):
            try container.encode("markets", forKey: .type)
            try container.encode(destination, forKey: .payload)
        case .news(let destination):
            try container.encode("news", forKey: .type)
            try container.encode(destination, forKey: .payload)
        case .watchlist(let destination):
            try container.encode("watchlist", forKey: .type)
            try container.encode(destination, forKey: .payload)
        }
    }
}

// Push-onto-current-stack scenario: Markets -> CoinDetail -> PriceAlerts.
public enum MarketsDestination: Codable, Sendable, Equatable {
    case coinDetail(CoinDetailDestination)

    private enum CodingKeys: String, CodingKey { case type, payload }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "coinDetail":
            self = .coinDetail(try container.decode(CoinDetailDestination.self, forKey: .payload))
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown markets destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .coinDetail(let destination):
            try container.encode("coinDetail", forKey: .type)
            try container.encode(destination, forKey: .payload)
        }
    }
}

public enum CoinDetailDestination: Codable, Sendable, Equatable {
    case show(coinId: String, next: PriceAlertDestination?)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private struct ShowPayload: Codable, Sendable, Equatable {
        let coinId: String
        let next: PriceAlertDestination?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "show":
            let payload = try container.decode(ShowPayload.self, forKey: .payload)
            self = .show(coinId: payload.coinId, next: payload.next)
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown coin detail destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .show(let coinId, let next):
            try container.encode("show", forKey: .type)
            try container.encode(ShowPayload(coinId: coinId, next: next), forKey: .payload)
        }
    }
}

public enum PriceAlertDestination: Codable, Sendable, Equatable {
    case show(coinId: String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private struct ShowPayload: Codable, Sendable, Equatable {
        let coinId: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "show":
            self = .show(coinId: try container.decode(ShowPayload.self, forKey: .payload).coinId)
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown price alert destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .show(let coinId):
            try container.encode("show", forKey: .type)
            try container.encode(ShowPayload(coinId: coinId), forKey: .payload)
        }
    }
}

// Modal-with-X scenario: News opens as a sheet with its own dismiss button.
public enum NewsDestination: Codable, Sendable, Equatable {
    case list
    case articleDetail(articleId: String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private struct ArticleDetailPayload: Codable, Sendable, Equatable {
        let articleId: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "list":
            self = .list
        case "articleDetail":
            self = .articleDetail(articleId: try container.decode(ArticleDetailPayload.self, forKey: .payload).articleId)
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown news destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .list:
            try container.encode("list", forKey: .type)
        case .articleDetail(let articleId):
            try container.encode("articleDetail", forKey: .type)
            try container.encode(ArticleDetailPayload(articleId: articleId), forKey: .payload)
        }
    }
}

// Back-always-home scenario: Watchlist Search -> Confirm; back from Confirm
// always pops to the app's root, never to Search.
public enum WatchlistDestination: Codable, Sendable, Equatable {
    case search
    case confirm(coinId: String, coinName: String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private struct ConfirmPayload: Codable, Sendable, Equatable {
        let coinId: String
        let coinName: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "search":
            self = .search
        case "confirm":
            let payload = try container.decode(ConfirmPayload.self, forKey: .payload)
            self = .confirm(coinId: payload.coinId, coinName: payload.coinName)
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown watchlist destination type: \(other)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .search:
            try container.encode("search", forKey: .type)
        case .confirm(let coinId, let coinName):
            try container.encode("confirm", forKey: .type)
            try container.encode(ConfirmPayload(coinId: coinId, coinName: coinName), forKey: .payload)
        }
    }
}
