import CryptoCoreKit
import SwiftUI

public struct CoinListView: View {
    @ObservedObject var viewModel: CoinListViewModel
    let onSelect: (String) -> Void

    public init(viewModel: CoinListViewModel, onSelect: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if viewModel.isLoadingInitial && viewModel.coins.isEmpty {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.coins.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.coins, id: \.coinId) { coin in
                        Button {
                            onSelect(coin.coinId)
                        } label: {
                            row(for: coin)
                        }
                        .listRowBackground(Color.black)
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: coin)
                        }
                    }

                    if viewModel.isLoadingMore {
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
                    await viewModel.refresh()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Browse coins")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInitialIfNeeded()
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
