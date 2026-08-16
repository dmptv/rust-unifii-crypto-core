import Foundation

// Deep-link payload contract: mirrors the coordinator hierarchy one-to-one.
// A push notification carries a JSON-encoded AppDestination; each level is
// decoded and delegated to the matching coordinator without presenting
// anything, until a case that carries its own display parameters is reached.

public enum AppDestination: Codable, Sendable, Equatable {
    case markets(MarketsDestination)
    case news(NewsDestination)
    case watchlist(WatchlistDestination)
}

// Push-onto-current-stack scenario: Markets -> CoinDetail -> PriceAlerts.
public enum MarketsDestination: Codable, Sendable, Equatable {
    case coinDetail(CoinDetailDestination)
}

public enum CoinDetailDestination: Codable, Sendable, Equatable {
    case show(coinId: String, next: PriceAlertDestination?)
}

public enum PriceAlertDestination: Codable, Sendable, Equatable {
    case show(coinId: String)
}

// Modal-with-X scenario: News opens as a sheet with its own dismiss button.
public enum NewsDestination: Codable, Sendable, Equatable {
    case list
    case articleDetail(articleId: String)
}

// Back-always-home scenario: Watchlist Search -> Confirm; back from Confirm
// always pops to the app's root, never to Search.
public enum WatchlistDestination: Codable, Sendable, Equatable {
    case search
    case confirm(coinId: String, coinName: String)
}
