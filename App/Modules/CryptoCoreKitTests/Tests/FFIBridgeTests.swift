import CryptoCoreKit
import XCTest

// Exercises the async FFI boundary against the real CoinGecko API - same
// no-mocking philosophy as crypto_core's own Rust-side network_tests.
final class FFIBridgeTests: XCTestCase {
    func testGetPriceAsyncReturnsRealPrice() async throws {
        let info = try await getPriceAsync(coinId: "bitcoin")
        XCTAssertEqual(info.coinId, "bitcoin")
        XCTAssertGreaterThan(info.usdPrice, 0)
    }

    func testGetPriceAsyncThrowsTypedErrorForInvalidInput() async {
        do {
            _ = try await getPriceAsync(coinId: "not a valid id!!")
            XCTFail("Expected PriceError.InvalidInput to be thrown")
        } catch let error as PriceError {
            guard case .InvalidInput = error else {
                XCTFail("Expected .InvalidInput, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected a PriceError, got \(error)")
        }
    }
}
