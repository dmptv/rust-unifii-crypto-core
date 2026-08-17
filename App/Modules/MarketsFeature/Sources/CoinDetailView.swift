import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct CoinDetailView: View {
    let store: StoreOf<CoinDetailFeature>

    public init(store: StoreOf<CoinDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                if let details = store.details {
                    Text(details.name)
                        .font(DSFont.screenTitle)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(details.symbol.uppercased())
                        .font(DSFont.subheadline)
                        .foregroundStyle(DSColor.textSecondary)

                    Text("$\(String(format: "%.2f", details.currentPriceUsd))")
                        .font(DSFont.priceNumber)
                        .foregroundStyle(DSColor.textPrimary)

                    if !details.description.isEmpty {
                        Text(details.description)
                            .font(DSFont.body)
                            .foregroundStyle(DSColor.textSecondary)
                            .lineLimit(6)
                    }

                    Button("Set price alert") {
                        store.send(.setAlertTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DSSpacing.sm)
                }
            }
            .padding()
        }
        .requestState(isLoading: store.isLoading, errorMessage: store.errorMessage)
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle(store.details?.name ?? "Coin")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }
}
