import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct AsyncDemoView: View {
    let store: StoreOf<AsyncPriceFeature>

    public init(store: StoreOf<AsyncPriceFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Async")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(DSColor.textPrimary)
                Text("Swift async/await over UniFFI · TCA")
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColor.textSecondary)
            }

            Divider().overlay(DSColor.divider)

            VStack(alignment: .leading, spacing: 10) {
                Text("ETH PRICE")
                    .font(DSFont.captionBold)
                    .foregroundStyle(DSColor.textSecondary)

                resultCard(result: store.priceResult, errorDetail: store.priceErrorDetail)

                Button("Get ETH price") {
                    store.send(.fetchPriceTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(DSColor.accent)
                .frame(maxWidth: .infinity)
                .disabled(store.isPriceLoading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ERROR HANDLING")
                    .font(DSFont.captionBold)
                    .foregroundStyle(DSColor.textSecondary)

                resultCard(result: store.errorDemoResult, errorDetail: store.errorDemoDetail)

                Button("Trigger invalid coin") {
                    store.send(.triggerErrorDemoTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(DSColor.error)
                .frame(maxWidth: .infinity)
                .disabled(store.isErrorDemoLoading)
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(DSColor.background.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func resultCard(result: String?, errorDetail: String?) -> some View {
        Group {
            if let errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(DSFont.captionBold)
                        .foregroundStyle(DSColor.error)
                    Text(errorDetail)
                        .font(DSFont.emphasis)
                        .foregroundStyle(DSColor.textPrimary)
                }
            } else {
                Text(result ?? "—")
                    .font(DSFont.heroNumber)
                    .foregroundStyle(DSColor.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DSSpacing.sm)
    }
}
