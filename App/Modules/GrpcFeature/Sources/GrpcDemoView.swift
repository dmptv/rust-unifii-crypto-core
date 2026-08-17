import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct GrpcDemoView: View {
    @Bindable var store: StoreOf<GrpcFeature>

    public init(store: StoreOf<GrpcFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: 2) {
                Text("gRPC")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(DSColor.textPrimary)
                Text("Rust as a gRPC client · Buf's Eliza demo")
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColor.textSecondary)
            }

            Divider().overlay(DSColor.divider)

            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR MESSAGE")
                    .font(DSFont.captionBold)
                    .foregroundStyle(DSColor.textSecondary)

                TextField("Say something to Eliza", text: $store.sentence, axis: .vertical)
                    .foregroundStyle(DSColor.textPrimary)
                    .padding(DSSpacing.md)
                    .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.medium))

                Button("Send") {
                    store.send(.sendTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(DSColor.accent)
                .frame(maxWidth: .infinity)
                .disabled(store.isLoading || store.sentence.isEmpty)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ELIZA REPLIES")
                    .font(DSFont.captionBold)
                    .foregroundStyle(DSColor.textSecondary)

                resultCard
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(DSColor.background.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private var resultCard: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .tint(DSColor.textPrimary)
            } else if let errorDetail = store.errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(DSFont.captionBold)
                        .foregroundStyle(DSColor.error)
                    Text(errorDetail)
                        .font(DSFont.emphasis)
                        .foregroundStyle(DSColor.textPrimary)
                }
            } else {
                Text(store.reply ?? "—")
                    .font(DSFont.resultText)
                    .foregroundStyle(DSColor.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DSSpacing.sm)
    }
}
