import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let dailyIdentifier = "com.smartstylist.daily-look"

    // Returns true when the user has already granted permission or just granted it now.
    // Subsequent calls after .denied/.authorized are silent no-ops (system handles this).
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            DebugLogger.shared.log("Notification permission request failed: \(error.localizedDescription)")
            return false
        }
    }

    // Replaces any existing daily notification with a fresh one.
    // Silently returns if the user has not granted permission.
    func scheduleDailyLookNotification() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized
           || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.notificationDailyTitle
        content.body  = Strings.notificationDailyBody
        content.sound = .default
        content.badge = 1

        // Fire at 08:00 every day, repeating.
        var components    = DateComponents()
        components.hour   = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyIdentifier,
            content: content,
            trigger: trigger
        )

        // Remove first so re-scheduling (e.g. after language change) always succeeds.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            DebugLogger.shared.log("Notification scheduling failed: \(error.localizedDescription)")
        }
    }

    // Convenience: request permission, then schedule if granted.
    func requestAndSchedule() async {
        let granted = await requestPermission()
        if granted { await scheduleDailyLookNotification() }
    }
}
