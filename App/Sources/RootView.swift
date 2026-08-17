import SwiftUI
import MarketsFeature
import NewsFeature
import WatchlistFeature
import NavigationKit
import AsyncFeature
import ComposableArchitecture
import GrpcFeature

/// Composition root: the one place in the app that constructs the view
/// models and wires them to their views. Views receive their dependencies
/// via `init` rather than creating them internally with `@StateObject` —
/// this keeps `AsyncDemoView`/`GrpcDemoView` free of hidden construction
/// logic, so each can be previewed or tested with a substitute store.
struct RootView: View {
    @State private var asyncStore = Store(initialState: AsyncPriceFeature.State()) {
        AsyncPriceFeature()
    }
    @State private var grpcStore = Store(initialState: GrpcFeature.State()) {
        GrpcFeature()
    }
    // Owned by CryptoCoreApp, not here: DeepLinkRouter needs the same
    // store/coordinator instances RootView displays, and that wiring has to
    // happen before any notification can be handled - see
    // CryptoCoreApp.swift.
    let marketsStore: StoreOf<MarketsFeature>
    @ObservedObject var newsCoordinator: NewsCoordinator
    @ObservedObject var watchlistCoordinator: WatchlistCoordinator
    @ObservedObject var tabSelection: TabSelectionModel

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            MarketsCoordinatorView(store: marketsStore)
                .tabItem {
                    Label("Live", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.live)

            AsyncDemoView(store: asyncStore)
                .tabItem {
                    Label("Async", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(AppTab.async)

            GrpcDemoView(store: grpcStore)
                .tabItem {
                    Label("gRPC", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(AppTab.grpc)

            DebugPushTriggerView()
                .tabItem {
                    Label("Push", systemImage: "bell.badge")
                }
                .tag(AppTab.push)
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
