import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    @Published var defaultServer: String {
        didSet {
            UserDefaults.standard.set(defaultServer, forKey: Keys.defaultServer)
            restartAll()
        }
    }

    @Published private(set) var subscriptions: [Subscription] = [] {
        didSet { persistSubscriptions() }
    }

    @Published private(set) var messages: [NtfyMessage] = [] {
        didSet { persistMessages() }
    }

    @Published var notificationsPaused: Bool {
        didSet { UserDefaults.standard.set(notificationsPaused, forKey: Keys.paused) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published var soundName: String {
        didSet { UserDefaults.standard.set(soundName, forKey: Keys.soundName) }
    }

    @Published var highPrioritySoundEnabled: Bool {
        didSet { UserDefaults.standard.set(highPrioritySoundEnabled, forKey: Keys.highPrioritySoundEnabled) }
    }

    @Published var highPrioritySoundName: String {
        didSet { UserDefaults.standard.set(highPrioritySoundName, forKey: Keys.highPrioritySoundName) }
    }

    @Published private(set) var launchAtLogin: Bool = false

    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: Keys.language)
            Store.applyLanguageOverride(language)
        }
    }

    // Computed from the bundle so newly translated languages show up
    // automatically without touching this list. Each language is shown
    // in its own name (e.g. "Deutsch", "日本語") regardless of the
    // current UI language, matching how macOS itself presents language
    // pickers.
    static var availableLanguages: [(code: String, displayName: String)] {
        var result: [(code: String, displayName: String)] = [("system", "System default")]
        let codes = Bundle.main.localizations
            .filter { $0 != "Base" }
            .sorted()
        for code in codes {
            let locale = Locale(identifier: code)
            let name = locale.localizedString(forIdentifier: code)?
                .capitalized(with: locale)
                ?? code
            result.append((code: code, displayName: name))
        }
        return result
    }

    static func applyLanguageOverride(_ language: String) {
        let defaults = UserDefaults.standard
        if language == "system" {
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set([language], forKey: "AppleLanguages")
        }
    }

    static let availableSounds: [String] = [
        "default",
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]

    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let messagesLimit = 200

    private enum Keys {
        static let defaultServer = "defaultServer"
        static let subscriptions = "subscriptions"
        static let messages = "messages"
        static let paused = "notificationsPaused"
        static let soundEnabled = "soundEnabled"
        static let soundName = "soundName"
        static let highPrioritySoundEnabled = "highPrioritySoundEnabled"
        static let highPrioritySoundName = "highPrioritySoundName"
        static let language = "language"
    }

    private init() {
        let defaults = UserDefaults.standard
        self.defaultServer = defaults.string(forKey: Keys.defaultServer) ?? "https://ntfy.sh"
        self.notificationsPaused = defaults.bool(forKey: Keys.paused)
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.soundName = defaults.string(forKey: Keys.soundName) ?? "default"
        self.highPrioritySoundEnabled = defaults.bool(forKey: Keys.highPrioritySoundEnabled)
        self.highPrioritySoundName = defaults.string(forKey: Keys.highPrioritySoundName) ?? "Hero"
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.language = defaults.string(forKey: Keys.language) ?? "system"
        if let data = defaults.data(forKey: Keys.subscriptions),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            self.subscriptions = decoded
        }
        if let data = defaults.data(forKey: Keys.messages),
           let decoded = try? JSONDecoder().decode([NtfyMessage].self, from: data) {
            self.messages = decoded
        }
    }

    // MARK: - Public API

    var unreadCount: Int { messages.lazy.filter { !$0.read }.count }

    func messages(for subscriptionID: UUID) -> [NtfyMessage] {
        messages.filter { $0.subscriptionID == subscriptionID }
    }

    func addSubscription(_ sub: Subscription) {
        subscriptions.append(sub)
        startStream(for: sub)
    }

    func updateSubscription(_ sub: Subscription) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[idx] = sub
        startStream(for: sub)
    }

    func removeSubscription(_ sub: Subscription) {
        tasks[sub.id]?.cancel()
        tasks.removeValue(forKey: sub.id)
        subscriptions.removeAll { $0.id == sub.id }
        messages.removeAll { $0.subscriptionID == sub.id }
    }

    func markAllRead() {
        for i in messages.indices { messages[i].read = true }
    }

    func markRead(_ message: NtfyMessage) {
        guard let i = messages.firstIndex(where: { $0.id == message.id }) else { return }
        if !messages[i].read {
            messages[i].read = true
        }
    }

    func removeMessage(_ message: NtfyMessage) {
        messages.removeAll { $0.id == message.id }
    }

    func sendTestMessage(_ sub: Subscription) {
        let server = sub.effectiveServer(default: defaultServer)
        let encoded = sub.topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sub.topic
        guard let url = URL(string: "\(server)/\(encoded)") else { return }
        let token = sub.token
        Task.detached {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("Test notification", forHTTPHeaderField: "Title")
            req.setValue("https://github.com/akandor/ntfyme", forHTTPHeaderField: "Click")
            if let token, !token.isEmpty {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let body = "🍁 You can attach files and URLs to messages too\nSo I heard you like ntfyme? If that's true, go to GitHub and star it, or to the App Store and rate it. Thanks! Oh yeah, this is a test notification."
            req.httpBody = body.data(using: .utf8)
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled, SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            } else if !enabled, SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // fall through — actual state below reflects what really happened
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func dismissFromPopup(_ message: NtfyMessage) {
        guard let i = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[i].popupDismissed = true
        messages[i].read = true
    }

    var popupMessages: [NtfyMessage] {
        messages.filter { !$0.popupDismissed }
    }

    func clearMessages() {
        messages = []
    }

    func startAll() {
        for sub in subscriptions { startStream(for: sub) }
    }

    func restartAll() {
        for (_, t) in tasks { t.cancel() }
        tasks.removeAll()
        startAll()
    }

    // MARK: - Streaming

    private func startStream(for sub: Subscription) {
        tasks[sub.id]?.cancel()
        let serverDefault = defaultServer
        let subID = sub.id
        let topic = sub.topic
        let serverOverride = sub.serverURL
        let token = sub.token
        tasks[sub.id] = Task { [weak self] in
            await Self.streamLoop(
                subID: subID,
                topic: topic,
                serverOverride: serverOverride,
                defaultServer: serverDefault,
                token: token,
                onMessage: { msg in
                    Task { @MainActor [weak self] in self?.receive(msg, subID: subID) }
                }
            )
        }
    }

    @MainActor
    private func receive(_ msg: NtfyMessage, subID: UUID) {
        var tagged = msg
        tagged.subscriptionID = subID
        tagged.read = false
        if let idx = messages.firstIndex(where: { $0.id == tagged.id }) {
            messages[idx] = tagged
        } else {
            messages.insert(tagged, at: 0)
            if messages.count > messagesLimit {
                messages.removeLast(messages.count - messagesLimit)
            }
        }
        if !notificationsPaused {
            NotificationService.shared.deliver(tagged)
        }
    }

    nonisolated private static func streamLoop(
        subID: UUID,
        topic: String,
        serverOverride: String?,
        defaultServer: String,
        token: String?,
        onMessage: @Sendable @escaping (NtfyMessage) -> Void
    ) async {
        var backoff: UInt64 = 1_000_000_000
        let maxBackoff: UInt64 = 30_000_000_000

        while !Task.isCancelled {
            let sub = Subscription(id: subID, topic: topic, serverURL: serverOverride, token: token)
            guard let url = sub.streamURL(default: defaultServer) else {
                try? await Task.sleep(nanoseconds: maxBackoff)
                continue
            }
            var req = URLRequest(url: url)
            req.timeoutInterval = .infinity
            if let token, !token.isEmpty {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                backoff = 1_000_000_000
                for try await line in bytes.lines {
                    if Task.isCancelled { break }
                    guard !line.isEmpty, let data = line.data(using: .utf8) else { continue }
                    guard let msg = try? JSONDecoder().decode(NtfyMessage.self, from: data) else { continue }
                    if msg.event == nil || msg.event == "message" {
                        onMessage(msg)
                    }
                }
            } catch {
                // fall through to backoff/reconnect
            }
            if Task.isCancelled { break }
            try? await Task.sleep(nanoseconds: backoff)
            backoff = min(backoff * 2, maxBackoff)
        }
    }

    // MARK: - Persistence

    private func persistSubscriptions() {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: Keys.subscriptions)
        }
    }

    private func persistMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: Keys.messages)
        }
    }
}
