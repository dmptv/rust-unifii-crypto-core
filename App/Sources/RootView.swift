import SwiftUI

/// Composition root: the one place in the app that constructs the view
/// models and wires them to their views. Views receive their dependencies
/// via `init` rather than creating them internally with `@StateObject` —
/// this keeps `LiveDashboardView`/`AsyncDemoView` free of hidden
/// construction logic, so each can be previewed or tested with a
/// substitute view model instead of a real one.
struct RootView: View {
    @StateObject private var tickerViewModel = TickerViewModel()
    @StateObject private var asyncPriceViewModel = AsyncPriceViewModel()

    var body: some View {
        TabView {
            LiveDashboardView(viewModel: tickerViewModel)
                .tabItem {
                    Label("Live", systemImage: "chart.line.uptrend.xyaxis")
                }

            AsyncDemoView(viewModel: asyncPriceViewModel)
                .tabItem {
                    Label("Async", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .preferredColorScheme(.dark)
    }
}
