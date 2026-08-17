import SwiftUI
import ComposableArchitecture

@main
struct CryptoCoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appStore = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: appStore)
                .onAppear {
                    appDelegate.deepLinkRouter = DeepLinkRouter(store: appStore)
                }
        }
    }
}
