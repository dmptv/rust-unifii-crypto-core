import ComposableArchitecture
import DesignSystemKit
import SwiftUI

public struct WatchlistSearchView: View {
    @Bindable var store: StoreOf<WatchlistSearchFeature>

    public init(store: StoreOf<WatchlistSearchFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search coins", text: $store.query)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .padding()

            if store.isLoading {
                ProgressView()
                    .padding(.top, DSSpacing.xl)
            } else if let error = store.errorMessage {
                Text(error)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.error)
                    .padding()
            }

            List(store.results, id: \.coinId) { result in
                Button {
                    store.send(.coinTapped(coinId: result.coinId, coinName: result.name))
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .foregroundStyle(DSColor.textPrimary)
                            Text(result.symbol.uppercased())
                                .font(DSFont.caption)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                        Spacer()
                        if let rank = result.marketCapRank {
                            Text("#\(rank)")
                                .font(DSFont.caption)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                    }
                }
                .listRowBackground(DSColor.background)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("Add to watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}
