import SwiftUI

// The back control here deliberately does not use the system back button:
// it always dismisses the whole Watchlist flow (coordinator.dismiss())
// instead of popping to Search, since a deep link can land here directly
// without Search ever having been on the stack.
public struct WatchlistConfirmView: View {
    @ObservedObject var viewModel: WatchlistConfirmViewModel
    let onDismiss: () -> Void

    public init(viewModel: WatchlistConfirmViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(viewModel.isAdded ? "Added to watchlist" : "Add to watchlist?")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(viewModel.coinName)
                .font(.title2)
                .foregroundStyle(.gray)

            if viewModel.isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            } else {
                Button("Confirm") {
                    viewModel.confirm()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
