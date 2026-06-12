import SwiftUI

enum Theme {
    static let palette: [Color] = [.blue, .purple, .orange, .pink, .indigo, .teal, .mint, .cyan]

    // Curated palette the user can pick from in the subscription editor.
    static let availableColors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("teal", .teal),
        ("cyan", .cyan),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink),
        ("brown", .brown),
        ("gray", .gray)
    ]

    // Curated SF Symbols list. Picked to cover the common ntfy usage
    // (alerts, infra, IoT, comms, weather, finance, …) without being a
    // jumble of every symbol the system ships.
    static let availableIcons: [String] = [
        "bell.fill", "bell.badge.fill", "megaphone.fill", "info.circle.fill",
        "exclamationmark.triangle.fill", "xmark.octagon.fill",
        "checkmark.circle.fill", "questionmark.circle.fill",
        "server.rack", "cpu", "internaldrive.fill", "externaldrive.fill",
        "network", "wifi", "globe", "lock.fill", "key.fill",
        "chevron.left.forwardslash.chevron.right", "hammer.fill",
        "terminal.fill", "ladybug.fill", "gearshape.fill",
        "sensor.fill", "door.left.hand.open", "lightbulb.fill",
        "camera.fill", "video.fill",
        "envelope.fill", "message.fill", "bubble.left.fill", "phone.fill",
        "house.fill", "building.2.fill", "car.fill", "airplane",
        "heart.fill", "cross.fill", "thermometer.medium",
        "dollarsign.circle.fill", "creditcard.fill", "cart.fill",
        "clock.fill", "alarm.fill", "calendar",
        "cloud.fill", "sun.max.fill", "bolt.fill", "snowflake",
        "leaf.fill", "flame.fill", "drop.fill",
        "gauge.medium", "tag.fill", "person.fill", "brain"
    ]

    static func color(named: String) -> Color? {
        availableColors.first { $0.name == named }?.color
    }

    static func tint(for message: NtfyMessage, subscription: Subscription? = nil) -> Color {
        if let name = subscription?.colorName, let c = color(named: name) {
            return c
        }
        return autoTint(for: message)
    }

    static func symbol(for message: NtfyMessage, subscription: Subscription? = nil) -> String {
        if let name = subscription?.iconName {
            return name
        }
        return autoSymbol(for: message)
    }

    // MARK: - Subscription-only helpers (used by row chips / editors when
    // there's no message yet to derive from).

    static func tint(for subscription: Subscription) -> Color {
        if let name = subscription.colorName, let c = color(named: name) {
            return c
        }
        var hasher = Hasher()
        hasher.combine(subscription.topic)
        return palette[abs(hasher.finalize()) % palette.count]
    }

    static func symbol(for subscription: Subscription) -> String {
        subscription.iconName ?? "bell.fill"
    }

    // MARK: - Priority indicator

    static func priorityIcon(_ level: NtfyMessage.PriorityLevel) -> String? {
        switch level {
        case .max: return "chevron.up.2"
        case .high: return "chevron.up"
        case .normal: return nil
        case .low: return "chevron.down"
        case .min: return "chevron.down.2"
        }
    }

    static func priorityTint(_ level: NtfyMessage.PriorityLevel) -> Color {
        switch level {
        case .max, .high: return .red
        case .normal: return .blue
        case .low, .min: return .secondary
        }
    }

    static func priorityAccessibilityLabel(_ level: NtfyMessage.PriorityLevel) -> LocalizedStringKey {
        switch level {
        case .max: return "Max priority"
        case .high: return "High priority"
        case .normal: return "Default priority"
        case .low: return "Low priority"
        case .min: return "Min priority"
        }
    }

    // MARK: - Auto heuristics

    private static func autoTint(for message: NtfyMessage) -> Color {
        let candidates = (message.tags ?? []) + [message.topic]
        for raw in candidates {
            let lc = raw.lowercased()
            if lc.contains("warning") || lc.contains("alert") || lc.contains("error")
                || lc.contains("fail") || lc.contains("critical") { return .red }
            if lc.contains("ok") || lc.contains("success") || lc.contains("done") { return .green }
            if lc.contains("github") || lc.contains("code") || lc.contains("deploy")
                || lc.contains("build") { return .purple }
            if lc.contains("motion") || lc.contains("sensor") || lc.contains("door")
                || lc.contains("camera") { return .blue }
            if lc.contains("server") || lc.contains("cpu") || lc.contains("disk") { return .red }
        }
        var hasher = Hasher()
        hasher.combine(message.topic)
        return palette[abs(hasher.finalize()) % palette.count]
    }

    private static func autoSymbol(for message: NtfyMessage) -> String {
        let candidates = (message.tags ?? []) + [message.topic]
        for raw in candidates {
            let lc = raw.lowercased()
            if lc.contains("warning") || lc.contains("alert") { return "bell.fill" }
            if lc.contains("error") || lc.contains("fail") { return "xmark.octagon.fill" }
            if lc.contains("ok") || lc.contains("success") { return "checkmark.circle.fill" }
            if lc.contains("github") || lc.contains("code") || lc.contains("deploy")
                || lc.contains("build") { return "chevron.left.forwardslash.chevron.right" }
            if lc.contains("motion") || lc.contains("sensor") { return "sensor.fill" }
            if lc.contains("door") { return "door.left.hand.open" }
            if lc.contains("camera") { return "camera.fill" }
            if lc.contains("server") { return "server.rack" }
            if lc.contains("cpu") { return "cpu.fill" }
            if lc.contains("disk") { return "internaldrive.fill" }
            if lc.contains("mail") || lc.contains("email") { return "envelope.fill" }
        }
        return "bell.fill"
    }
}
