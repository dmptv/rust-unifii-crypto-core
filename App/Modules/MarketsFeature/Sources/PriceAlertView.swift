import ComposableArchitecture
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
        VStack(alignment: .leading, spacing: 20) {
            Text("Price alert")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)
            Text(store.coinId)
                .font(.subheadline)
                .foregroundStyle(.gray)

            Toggle("Notify me", isOn: $notifyEnabled)
                .tint(.blue)

            if notifyEnabled {
                VStack(alignment: .leading) {
                    Text("Threshold: $\(Int(threshold))")
                        .foregroundStyle(.gray)
                    Slider(value: $threshold, in: 0...200_000, step: 100)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Price alert")
        .navigationBarTitleDisplayMode(.inline)
    }
}
