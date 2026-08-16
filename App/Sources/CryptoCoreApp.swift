import SwiftUI
import MarketsFeature
import NewsFeature
import WatchlistFeature

@main
struct CryptoCoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var marketsCoordinator = MarketsCoordinator(container: AppContainer.shared)
    @StateObject private var newsCoordinator = NewsCoordinator(container: AppContainer.shared)
    @StateObject private var watchlistCoordinator = WatchlistCoordinator(container: AppContainer.shared)

    var body: some Scene {
        WindowGroup {
            RootView(
                marketsCoordinator: marketsCoordinator,
                newsCoordinator: newsCoordinator,
                watchlistCoordinator: watchlistCoordinator
            )
            .onAppear {
                appDelegate.deepLinkRouter = DeepLinkRouter(
                    marketsCoordinator: marketsCoordinator,
                    newsCoordinator: newsCoordinator,
                    watchlistCoordinator: watchlistCoordinator
                )
            }
        }
    }
}
