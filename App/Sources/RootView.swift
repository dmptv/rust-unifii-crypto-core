import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LiveDashboardView()
                .tabItem {
                    Label("Live", systemImage: "chart.line.uptrend.xyaxis")
                }

            AsyncDemoView()
                .tabItem {
                    Label("Async", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .preferredColorScheme(.dark)
    }
}
