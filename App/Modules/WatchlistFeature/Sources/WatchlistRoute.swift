// Stack entries pushed inside the Watchlist modal's own NavigationStack.
// Search is always the root; Confirm is the only thing ever pushed onto it.
public enum WatchlistRoute: Hashable {
    case confirm(coinId: String, coinName: String)
}
