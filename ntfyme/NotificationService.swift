import Foundation
import UserNotifications
import AppKit

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        default:
            break
        }
    }

    func deliver(_ msg: NtfyMessage) {
        let content = UNMutableNotificationContent()
        content.title = Emoji.decorate(msg.displayTitle, tags: msg.tags)
        if !msg.displayBody.isEmpty {
            content.body = msg.displayBody
        }

        let store = Store.shared
        if store.soundEnabled {
            if store.soundName == "default" {
                content.sound = .default
            } else {
                content.sound = nil
                NSSound(named: store.soundName)?.play()
            }
        } else {
            content.sound = nil
        }

        if let click = msg.click {
            content.userInfo = ["click": click]
        }
        let request = UNNotificationRequest(
            identifier: msg.id,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func previewSound(named name: String) {
        if name == "default" {
            NSSound(named: "Funk")?.play()
        } else {
            NSSound(named: name)?.play()
        }
    }

    // Show banners even while app is foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let click = userInfo["click"] as? String, let url = URL(string: click) {
            Task { @MainActor in NSWorkspace.shared.open(url) }
        }
        completionHandler()
    }
}
