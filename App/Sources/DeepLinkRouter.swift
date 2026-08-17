import ComposableArchitecture
import Foundation
import NavigationKit

// Decodes the "destination" object out of a push payload's userInfo and
// sends it as one action to AppFeature's root Store. Routing logic itself
// (which tab, which child action) lives in the reducer now - this class is
// only the bridge from UNUserNotificationCenterDelegate's callback (a
// UIKit/system world) into TCA's .send().
@MainActor
final class DeepLinkRouter {
    private let store: StoreOf<AppFeature>

    init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    func handle(userInfo: [AnyHashable: Any]) {
        guard let destinationObject = userInfo["destination"] else { return }
        guard JSONSerialization.isValidJSONObject(destinationObject),
              let data = try? JSONSerialization.data(withJSONObject: destinationObject) else {
            return
        }
        guard let destination = try? JSONDecoder().decode(AppDestination.self, from: data) else {
            return
        }
        store.send(.deepLinkReceived(destination))
    }
}
