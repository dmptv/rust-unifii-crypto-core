import SwiftUI
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

public struct GrpcDemoView: View {
    @ObservedObject public var viewModel: GrpcViewModel
    @State private var sentence: String = "Hello, are you a real gRPC service?"

    public init(viewModel: GrpcViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("gRPC")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Rust as a gRPC client · Buf's Eliza demo")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Divider().overlay(Color.white.opacity(0.15))

            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR MESSAGE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                TextField("Say something to Eliza", text: $sentence, axis: .vertical)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                Button("Send") {
                    viewModel.ask(sentence)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isLoading || sentence.isEmpty)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ELIZA REPLIES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                resultCard
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private var resultCard: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorDetail = viewModel.errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text(errorDetail)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            } else {
                Text(viewModel.reply ?? "—")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
