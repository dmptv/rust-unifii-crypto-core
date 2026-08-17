import ComposableArchitecture
import CryptoCoreKit
import DesignSystemKit
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
                    .tint(DSColor.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.errorMessage, store.coins.isEmpty {
                Text(error)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.error)
                    .padding()
            } else {
                List {
                    ForEach(store.coins, id: \.coinId) { coin in
                        Button {
                            store.send(.coinTapped(coin.coinId))
                        } label: {
                            row(for: coin)
                        }
                        .listRowBackground(DSColor.background)
                        .onAppear {
                            store.send(.loadMoreIfNeeded(coin))
                        }
                    }

                    if store.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(DSColor.textPrimary)
                            Spacer()
                        }
                        .listRowBackground(DSColor.background)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await store.send(.refresh).finish()
                }
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("Browse coins")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func row(for coin: CoinListing) -> some View {
        HStack(spacing: DSSpacing.md) {
            if let rank = coin.marketCapRank {
                Text("#\(rank)")
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(width: DSSpacing.xxl, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .foregroundStyle(DSColor.textPrimary)
                Text(coin.symbol.uppercased())
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
            }
            Spacer()
            Text(formattedPrice(coin.currentPriceUsd))
                .foregroundStyle(DSColor.textPrimary)
                .font(DSFont.numericCompact)
        }
        .padding(.vertical, DSSpacing.xs)
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
