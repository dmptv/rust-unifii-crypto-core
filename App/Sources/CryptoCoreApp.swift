import SwiftUI
import ComposableArchitecture
import MarketsFeature
import NewsFeature
import WatchlistFeature

@main
struct CryptoCoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var marketsStore = Store(initialState: MarketsFeature.State()) {
        MarketsFeature()
    }
    @StateObject private var newsCoordinator = NewsCoordinator(container: AppContainer.shared)
    @StateObject private var watchlistCoordinator = WatchlistCoordinator(container: AppContainer.shared)
    @StateObject private var tabSelection = TabSelectionModel()

    var body: some Scene {
        WindowGroup {
            RootView(
                marketsStore: marketsStore,
                newsCoordinator: newsCoordinator,
                watchlistCoordinator: watchlistCoordinator,
                tabSelection: tabSelection
            )
            .onAppear {
                appDelegate.deepLinkRouter = DeepLinkRouter(
                    marketsStore: marketsStore,
                    newsCoordinator: newsCoordinator,
                    watchlistCoordinator: watchlistCoordinator,
                    tabSelection: tabSelection
                )
            }
        }
    }
}
