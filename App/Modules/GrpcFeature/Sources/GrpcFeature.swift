import ComposableArchitecture
import CryptoCoreKit
import ElizaProtoKit

@Reducer
public struct GrpcFeature {
    @ObservableState
    public struct State: Equatable {
        public var sentence: String = "Hello, are you a real gRPC service?"
        public var reply: String?
        public var errorDetail: String?
        public var isLoading = false

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case sendTapped
        case response(Result<String, GrpcFetchError>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .sendTapped:
                state.isLoading = true
                state.errorDetail = nil
                let sentence = state.sentence
                return .run { send in
                    await send(.response(Self.ask(sentence)))
                }

            case let .response(result):
                state.isLoading = false
                switch result {
                case let .success(reply):
                    state.reply = reply
                case let .failure(error):
                    state.reply = nil
                    state.errorDetail = error.message
                }
                return .none
            }
        }
    }

    // askEliza talks to a real external gRPC service (Buf's public Eliza
    // demo) — Rust is the gRPC client here (via tonic), but it hands back
    // raw protobuf wire bytes instead of a decoded type. Swift owns
    // deserialization on its own side, using ElizaProtoKit's generated
    // model of the exact same eliza.proto Rust used to make the call.
    private static func ask(_ sentence: String) async -> Result<String, GrpcFetchError> {
        do {
            let rawBytes = try await askEliza(sentence: sentence)
            let response = try Connectrpc_Eliza_V1_SayResponse(serializedBytes: rawBytes)
            return .success(response.sentence)
        } catch let error as ElizaError {
            return .failure(GrpcFetchError(message: detail(for: error)))
        } catch {
            return .failure(GrpcFetchError(message: "Failed to decode protobuf response: \(error)"))
        }
    }

    private static func detail(for error: ElizaError) -> String {
        switch error {
        case let .Network(reason):
            reason
        case let .InvalidInput(reason):
            reason
        }
    }
}

public struct GrpcFetchError: Error, Equatable, Sendable {
    public let message: String
}
