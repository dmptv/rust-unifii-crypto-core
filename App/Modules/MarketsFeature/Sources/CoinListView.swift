import ComposableArchitecture
import CryptoCoreKit
import SwiftUI

public struct CoinListView: View {
    let store: StoreOf<CoinListFeature>

    public init(store: StoreOf<CoinListFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoadingInitial && store.coins.isEmpty {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.errorMessage, store.coins.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            } else {
                List {
                    ForEach(store.coins, id: \.coinId) { coin in
                        Button {
                            store.send(.coinTapped(coin.coinId))
                        } label: {
                            row(for: coin)
                        }
                        .listRowBackground(Color.black)
                        .onAppear {
                            store.send(.loadMoreIfNeeded(coin))
                        }
                    }

                    if store.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(.white)
                            Spacer()
                        }
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await store.send(.refresh).finish()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Browse coins")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func row(for coin: CoinListing) -> some View {
        HStack(spacing: 12) {
            if let rank = coin.marketCapRank {
                Text("#\(rank)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .frame(width: 32, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .foregroundStyle(.white)
                Text(coin.symbol.uppercased())
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Text(formattedPrice(coin.currentPriceUsd))
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding(.vertical, 4)
    }

    private func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let body = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(body)"
    }
}
