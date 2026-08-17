import ComposableArchitecture
import DesignSystemKit
import SwiftUI

// The back control here deliberately does not use the system back button:
// it always sends backTapped, which the parent WatchlistFeature turns into
// clearing its whole path, since a deep link can land here directly
// without Search ever having been pushed.
public struct WatchlistConfirmView: View {
    let store: StoreOf<WatchlistConfirmFeature>

    public init(store: StoreOf<WatchlistConfirmFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            Text(store.isAdded ? "Added to watchlist" : "Add to watchlist?")
                .font(DSFont.sectionTitle)
                .foregroundStyle(DSColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(store.coinName)
                .font(.title2)
                .foregroundStyle(DSColor.textSecondary)

            if store.isAdded {
                Image(systemName: DSIcon.success)
                    .font(.system(size: DSIconSize.large))
                    .foregroundStyle(DSColor.success)
                    .accessibilityHidden(true)
            } else {
                Button("Confirm") {
                    store.send(.confirmTapped)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DSSpacing.xxxl)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DSColor.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: DSIcon.back)
                        .foregroundStyle(DSColor.textPrimary)
                }
                .minTapTarget()
                .accessibilityLabel("Back")
            }
        }
    }
}
