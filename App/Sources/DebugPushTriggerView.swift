import DesignSystemKit
import NavigationKit
import SwiftUI
import UserNotifications

// Dev-only convenience: schedules a real local notification (not a direct
// in-process call to DeepLinkRouter) so tapping it exercises the exact same
// AppDelegate -> UNUserNotificationCenterDelegate -> DeepLinkRouter pipeline
// a real remote push would, without needing `xcrun simctl push` from a
// terminal. The 4s delay gives enough time to back out of this screen (or
// just wait) before the banner appears.
private func scheduleTestPush(title: String, body: String, destination: AppDestination) {
    guard let data = try? JSONEncoder().encode(destination),
          let json = try? JSONSerialization.jsonObject(with: data) else {
        return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = ["destination": json]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}

private struct PushTriggerButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSFont.headline)
                    .foregroundStyle(DSColor.textPrimary)
                Text(subtitle)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.medium))
        }
    }
}

struct DebugPushTriggerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Push Debug")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(DSColor.textPrimary)
                Text("Schedules a real local notification in ~4s")
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColor.textSecondary)
            }

            Divider().overlay(DSColor.divider)

            PushTriggerButton(
                title: "Markets: Bitcoin -> Price Alert",
                subtitle: "Push onto current stack"
            ) {
                scheduleTestPush(
                    title: "Bitcoin is up 5%!",
                    body: "Tap to see details and set a price alert.",
                    destination: .markets(
                        .coinDetail(
                            .show(coinId: "bitcoin", next: .show(coinId: "bitcoin"))
                        )
                    )
                )
            }

            PushTriggerButton(
                title: "News: list",
                subtitle: "Modal with X"
            ) {
                scheduleTestPush(
                    title: "Crypto News",
                    body: "New headlines just dropped.",
                    destination: .news(.list)
                )
            }

            PushTriggerButton(
                title: "Watchlist: Search",
                subtitle: "Back always home - entry via Search"
            ) {
                scheduleTestPush(
                    title: "Track a new coin?",
                    body: "Search and add it to your watchlist.",
                    destination: .watchlist(.search)
                )
            }

            PushTriggerButton(
                title: "Watchlist: Confirm Ethereum (direct)",
                subtitle: "Back always home - skips Search entirely"
            ) {
                scheduleTestPush(
                    title: "Add Ethereum to your watchlist?",
                    body: "Tap to confirm.",
                    destination: .watchlist(.confirm(coinId: "ethereum", coinName: "Ethereum"))
                )
            }

            Spacer()
        }
        .padding()
        .padding(.bottom, 90)
        .safeAreaPadding(.top)
        .background(DSColor.background.ignoresSafeArea(edges: .bottom))
    }
}
