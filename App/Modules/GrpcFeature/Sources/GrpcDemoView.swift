import ComposableArchitecture
import SwiftUI

public struct GrpcDemoView: View {
    @Bindable var store: StoreOf<GrpcFeature>

    public init(store: StoreOf<GrpcFeature>) {
        self.store = store
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

                TextField("Say something to Eliza", text: $store.sentence, axis: .vertical)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                Button("Send") {
                    store.send(.sendTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .disabled(store.isLoading || store.sentence.isEmpty)
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
            if store.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorDetail = store.errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text(errorDetail)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            } else {
                Text(store.reply ?? "—")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
