import Combine
import CryptoCoreKit
import ElizaProtoKit

@MainActor
public final class GrpcViewModel: ObservableObject {
    @Published public var reply: String?
    @Published public var errorDetail: String?
    @Published public var isLoading = false

    public init() {}

    public func ask(_ sentence: String) {
        isLoading = true
        errorDetail = nil
        Task {
            do {
                // askEliza talks to a real external gRPC service (Buf's
                // public Eliza demo) — Rust is the gRPC client here (via
                // tonic), but it hands back raw protobuf wire bytes instead
                // of a decoded type. Swift owns deserialization on its own
                // side, using ElizaProtoKit's generated model of the exact
                // same eliza.proto Rust used to make the call.
                let rawBytes = try await askEliza(sentence: sentence)
                let response = try Connectrpc_Eliza_V1_SayResponse(serializedBytes: rawBytes)
                reply = response.sentence
            } catch let error as ElizaError {
                reply = nil
                errorDetail = detail(for: error)
            } catch {
                reply = nil
                errorDetail = "Failed to decode protobuf response: \(error)"
            }
            isLoading = false
        }
    }

    private func detail(for error: ElizaError) -> String {
        switch error {
        case let .Network(reason):
            reason
        case let .InvalidInput(reason):
            reason
        }
    }
}
