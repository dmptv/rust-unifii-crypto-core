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
    @StateObject private var marketsCoordinator = MarketsCoordinator(container: AppContainer.shared)
    @StateObject private var newsCoordinator = NewsCoordinator(container: AppContainer.shared)
    @StateObject private var watchlistCoordinator = WatchlistCoordinator(container: AppContainer.shared)

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
        }
        .preferredColorScheme(.dark)
        // Stand-in for the push-notification trigger that lands in step
        // 2.4: News is reachable from any tab, exactly as a deep link
        // would present it, without disturbing the tabs themselves.
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                Button {
                    watchlistCoordinator.handle(.search)
                } label: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                // TEMPORARY: simulates a deep link landing directly on
                // Confirm (skipping Search) — exercises the "back always
                // home" behavior without needing to type into the search
                // field. Remove once step 2.4 wires real deep links and
                // simctl push testing replaces this.
                Button {
                    watchlistCoordinator.handle(.confirm(coinId: "bitcoin", coinName: "Bitcoin"))
                } label: {
                    Image(systemName: "star.circle")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Button {
                    newsCoordinator.handle(.list)
                } label: {
                    Image(systemName: "newspaper.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.top, 56)
            .padding(.trailing, 16)
        }
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
