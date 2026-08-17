import SwiftUI
import DesignSystemKit
import MarketsFeature
import NewsFeature
import WatchlistFeature
import AsyncFeature
import ComposableArchitecture
import GrpcFeature

/// Composition root: the one place in the app that scopes AppFeature's
/// single Store down into each tab's own StoreOf<Feature>.
struct RootView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab) {
            MarketsCoordinatorView(store: store.scope(state: \.markets, action: \.markets))
                .tabItem {
                    Label("Live", systemImage: DSIcon.tabLive)
                }
                .tag(AppTab.live)

            NewsCoordinatorView(store: store.scope(state: \.news, action: \.news))
                .tabItem {
                    Label("News", systemImage: DSIcon.tabNews)
                }
                .tag(AppTab.news)

            WatchlistCoordinatorView(store: store.scope(state: \.watchlist, action: \.watchlist))
                .tabItem {
                    Label("Watchlist", systemImage: DSIcon.tabWatchlist)
                }
                .tag(AppTab.watchlist)

            AsyncDemoView(store: store.scope(state: \.async, action: \.async))
                .tabItem {
                    Label("Async", systemImage: DSIcon.tabAsync)
                }
                .tag(AppTab.async)

            GrpcDemoView(store: store.scope(state: \.grpc, action: \.grpc))
                .tabItem {
                    Label("gRPC", systemImage: DSIcon.tabGrpc)
                }
                .tag(AppTab.grpc)

            DebugPushTriggerView()
                .tabItem {
                    Label("Push", systemImage: DSIcon.tabPush)
                }
                .tag(AppTab.push)
        }
        .preferredColorScheme(.dark)
    }
}
