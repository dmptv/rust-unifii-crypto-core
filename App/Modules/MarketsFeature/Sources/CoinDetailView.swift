import ComposableArchitecture
import SwiftUI

public struct CoinDetailView: View {
    let store: StoreOf<CoinDetailFeature>

    public init(store: StoreOf<CoinDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let details = store.details {
                    Text(details.name)
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(details.symbol.uppercased())
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    Text("$\(String(format: "%.2f", details.currentPriceUsd))")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    if !details.description.isEmpty {
                        Text(details.description)
                            .font(.body)
                            .foregroundStyle(.gray)
                            .lineLimit(6)
                    }

                    Button("Set price alert") {
                        store.send(.setAlertTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(store.details?.name ?? "Coin")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }
}
