import Foundation
import UserNotifications

@Observable
@MainActor
final class NotificationManager {
    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            await refreshStatus()
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
}
