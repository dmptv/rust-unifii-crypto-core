import CryptoCoreKit

// crypto_core's getCoinDetails is a synchronous, network-calling FFI
// function; conforming types are expected to hop off the calling thread
// themselves so this can be awaited safely from the main actor.
public protocol MarketsServicing {
    func coinDetails(coinId: String) async throws -> CoinDetails
}
