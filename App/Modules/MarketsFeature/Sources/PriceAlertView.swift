import SwiftUI

// Terminal screen of the Markets flow — no service call, so no view model:
// the "notify me" toggle is local UI state, not business logic.
public struct PriceAlertView: View {
    let coinId: String
    @State private var notifyEnabled = false
    @State private var threshold: Double = 0

    public init(coinId: String) {
        self.coinId = coinId
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Price alert")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)
            Text(coinId)
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
