import UIKit
import UserNotifications

// UIApplicationDelegateAdaptor bridge: SwiftUI's App protocol has no hook
// for UNUserNotificationCenterDelegate, so a thin UIKit delegate is still
// needed to receive notification taps and hand them to DeepLinkRouter.
// deepLinkRouter is set after CryptoCoreApp constructs its coordinators,
// since those don't exist yet at applicationDidFinishLaunching time.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor var deepLinkRouter: DeepLinkRouter?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        return true
    }

    // Without this, a push that arrives while the app is already in the
    // foreground is delivered silently — no banner, nothing to tap.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            deepLinkRouter?.handle(userInfo: response.notification.request.content.userInfo)
            completionHandler()
        }
    }
}
