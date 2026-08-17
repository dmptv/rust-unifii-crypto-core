import ComposableArchitecture
import DesignSystemKit
import SwiftUI

// Terminal screen of the Markets flow — no service call, so the "notify me"
// toggle stays local View @State (trivial UI state, not business logic)
// even though the screen is backed by a (nearly empty) PriceAlertFeature.
public struct PriceAlertView: View {
    let store: StoreOf<PriceAlertFeature>
    @State private var notifyEnabled = false
    @State private var threshold: Double = 0

    public init(store: StoreOf<PriceAlertFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Text("Price alert")
                .font(DSFont.priceNumber)
                .foregroundStyle(DSColor.textPrimary)
            Text(store.coinId)
                .font(DSFont.subheadline)
                .foregroundStyle(DSColor.textSecondary)

            Toggle("Notify me", isOn: $notifyEnabled)
                .tint(DSColor.accent)

            if notifyEnabled {
                VStack(alignment: .leading) {
                    Text("Threshold: $\(Int(threshold))")
                        .foregroundStyle(DSColor.textSecondary)
                    Slider(value: $threshold, in: 0...200_000, step: 100)
                }
            }

            Spacer()
        }
        .padding()
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("Price alert")
        .navigationBarTitleDisplayMode(.inline)
    }
}
