import SwiftUI

public struct WatchlistSearchView: View {
    @ObservedObject var viewModel: WatchlistSearchViewModel
    let onSelect: (String, String) -> Void

    public init(viewModel: WatchlistSearchViewModel, onSelect: @escaping (String, String) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search coins", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .padding()
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.queryChanged()
                }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 20)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            List(viewModel.results, id: \.coinId) { result in
                Button {
                    onSelect(result.coinId, result.name)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .foregroundStyle(.white)
                            Text(result.symbol.uppercased())
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        if let rank = result.marketCapRank {
                            Text("#\(rank)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .listRowBackground(Color.black)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Add to watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}
