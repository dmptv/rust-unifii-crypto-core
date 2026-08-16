// Presentation-level stack entries pushed by MarketsCoordinator. Deliberately
// separate from NavigationKit's MarketsDestination/CoinDetailDestination:
// those are the deep-link *payload* (what a push notification says to open),
// this is what's actually sitting on the NavigationStack right now.
public enum MarketsRoute: Hashable {
    case coinDetail(coinId: String)
    case priceAlert(coinId: String)
    case coinList
}
