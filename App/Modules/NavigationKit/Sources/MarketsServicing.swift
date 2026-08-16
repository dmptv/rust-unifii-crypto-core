import CryptoCoreKit

// crypto_core's getCoinDetails is a synchronous, network-calling FFI
// function; conforming types are expected to hop off the calling thread
// themselves so this can be awaited safely from the main actor.
public protocol MarketsServicing {
    func coinDetails(coinId: String) async throws -> CoinDetails

    // cursor is opaque: pass nil for the first page, then always pass back
    // exactly the nextCursor a previous page returned. Callers must not
    // parse or construct this string themselves.
    func coinsPage(cursor: String?) async throws -> CoinsPage
}
