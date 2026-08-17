import ComposableArchitecture
import SwiftUI

public struct AsyncDemoView: View {
    let store: StoreOf<AsyncPriceFeature>

    public init(store: StoreOf<AsyncPriceFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Async")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Swift async/await over UniFFI · TCA")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Divider().overlay(Color.white.opacity(0.15))

            VStack(alignment: .leading, spacing: 10) {
                Text("ETH PRICE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                resultCard(result: store.priceResult, errorDetail: store.priceErrorDetail)

                Button("Get ETH price") {
                    store.send(.fetchPriceTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .disabled(store.isPriceLoading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("ERROR HANDLING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)

                resultCard(result: store.errorDemoResult, errorDetail: store.errorDemoDetail)

                Button("Trigger invalid coin") {
                    store.send(.triggerErrorDemoTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
                .disabled(store.isErrorDemoLoading)
            }

            Spacer(minLength: 12)
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func resultCard(result: String?, errorDetail: String?) -> some View {
        Group {
            if let errorDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ERROR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text(errorDetail)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                }
            } else {
                Text(result ?? "—")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
