import SwiftUI

public struct CoinDetailView: View {
    @ObservedObject var viewModel: CoinDetailViewModel
    let onSetAlert: () -> Void

    public init(viewModel: CoinDetailViewModel, onSetAlert: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSetAlert = onSetAlert
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let details = viewModel.details {
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
                        onSetAlert()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(viewModel.details?.name ?? "Coin")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}
