import Foundation
import UserNotifications
import AppKit
import AVFoundation

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
            let isHighPriority = msg.priorityLevel.rawValue >= NtfyMessage.PriorityLevel.high.rawValue
            let chosen: String = (isHighPriority && store.highPrioritySoundEnabled)
                ? store.highPrioritySoundName
                : store.soundName
            if chosen == "default" {
                content.sound = .default
            } else {
                content.sound = nil
                Self.playSystemSound(named: chosen)
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
            Self.playSystemSound(named: "Funk")
        } else {
            Self.playSystemSound(named: name)
        }
    }

    // Keep one player alive across calls so the sound is actually heard
    // (an AVAudioPlayer that goes out of scope is stopped before its
    // buffer flushes). NSSound.play() would be simpler, but on the
    // sandbox it triggers AudioAnalytics' mach-lookup precondition and
    // crashes the process; AVAudioPlayer reading the .aiff file
    // directly avoids that path.
    private static var previewPlayer: AVAudioPlayer?

    private static func playSystemSound(named name: String) {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            previewPlayer = player
            player.prepareToPlay()
            player.play()
        } catch {
            // ignore — sound is non-essential
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
        let messageID = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        let clickURL = (userInfo["click"] as? String).flatMap(URL.init(string:))
        Task { @MainActor in
            Store.shared.markRead(id: messageID)
            if let clickURL {
                NSWorkspace.shared.open(clickURL)
            }
            completionHandler()
        }
    }
}
