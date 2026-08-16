import SwiftUI
import MarketsFeature
import NewsFeature
import WatchlistFeature
import NavigationKit
import AsyncFeature
import GrpcFeature

/// Composition root: the one place in the app that constructs the view
/// models and wires them to their views. Views receive their dependencies
/// via `init` rather than creating them internally with `@StateObject` —
/// this keeps `LiveDashboardView`/`AsyncDemoView`/`GrpcDemoView` free of
/// hidden construction logic, so each can be previewed or tested with a
/// substitute view model instead of a real one.
struct RootView: View {
    @StateObject private var tickerViewModel = TickerViewModel()
    @StateObject private var asyncPriceViewModel = AsyncPriceViewModel()
    @StateObject private var grpcViewModel = GrpcViewModel()
    // Owned by CryptoCoreApp, not here: DeepLinkRouter needs the same
    // coordinator instances RootView displays, and that wiring has to
    // happen before any notification can be handled - see
    // CryptoCoreApp.swift.
    @ObservedObject var marketsCoordinator: MarketsCoordinator
    @ObservedObject var newsCoordinator: NewsCoordinator
    @ObservedObject var watchlistCoordinator: WatchlistCoordinator

    var body: some View {
        TabView {
            MarketsCoordinatorView(coordinator: marketsCoordinator, tickerViewModel: tickerViewModel)
                .tabItem {
                    Label("Live", systemImage: "chart.line.uptrend.xyaxis")
                }

            AsyncDemoView(viewModel: asyncPriceViewModel)
                .tabItem {
                    Label("Async", systemImage: "arrow.triangle.2.circlepath")
                }

            GrpcDemoView(viewModel: grpcViewModel)
                .tabItem {
                    Label("gRPC", systemImage: "bubble.left.and.bubble.right")
                }

            DebugPushTriggerView()
                .tabItem {
                    Label("Push", systemImage: "bell.badge")
                }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $newsCoordinator.isPresented) {
            NewsCoordinatorView(coordinator: newsCoordinator)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $watchlistCoordinator.isPresented) {
            WatchlistCoordinatorView(coordinator: watchlistCoordinator)
                .preferredColorScheme(.dark)
        }
    }
}
