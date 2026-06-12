import SwiftUI
import AppKit

struct StatusBarPopupView: View {
    @EnvironmentObject var store: Store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    @State private var measuredListHeight: CGFloat = 0

    private let listMaxHeight: CGFloat = 420

    var body: some View {
        VStack(spacing: 0) {
            header
            messageSection
            menuSection
        }
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image("ntfyme")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(.primary)
                .opacity(0.85)
            Text("ntfy Notifications")
                .font(.system(size: 17, weight: .bold))
            Spacer()
            if store.unreadCount > 0 {
                Button {
                    store.markAllRead()
                } label: {
                    Text(verbatim: "\(store.unreadCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Mark all as read")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Messages

    @ViewBuilder
    private var messageSection: some View {
        if store.subscriptions.isEmpty {
            emptyState(
                symbol: "bell.slash",
                title: "No subscriptions yet",
                subtitle: "Add a topic in Settings to start receiving notifications."
            )
        } else if store.popupMessages.isEmpty {
            emptyState(
                symbol: "tray",
                title: "No new messages",
                subtitle: "Open View History to see past notifications."
            )
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 6) {
                    ForEach(store.popupMessages) { message in
                        MessageCard(
                            message: message,
                            subscription: subscription(for: message),
                            onClose: { store.dismissFromPopup(message) }
                        )
                        .onTapGesture {
                            store.markRead(message)
                            if let click = message.click, let url = URL(string: click) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: PopupListHeightKey.self, value: geo.size.height)
                    }
                )
            }
            .onPreferenceChange(PopupListHeightKey.self) { measuredListHeight = $0 }
            // MenuBarExtra's .window layout doesn't propose a height to its
            // children, so we have to commit one. Use the actual measured
            // content height (so a single card doesn't leave dead space
            // above the menu), capped at listMaxHeight; beyond that the
            // ScrollView scrolls. The fallback min keeps the first render
            // from being 0pt before the preference fires.
            .frame(height: min(max(measuredListHeight, 80), listMaxHeight))
        }
    }

    private func subscription(for message: NtfyMessage) -> Subscription? {
        guard let id = message.subscriptionID else { return nil }
        return store.subscriptions.first { $0.id == id }
    }

    private func emptyState(symbol: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Menu

    private var menuSection: some View {
        VStack(spacing: 1) {
            MenuRow(
                title: "Settings…",
                systemImage: "gearshape",
                shortcut: "⌘,"
            ) {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }

            if store.notificationsPaused {
                MenuRow(
                    title: "Resume Notifications",
                    systemImage: "play.fill"
                ) { store.notificationsPaused.toggle() }
            } else {
                MenuRow(
                    title: "Pause Notifications",
                    systemImage: "pause.fill"
                ) { store.notificationsPaused.toggle() }
            }

            MenuRow(
                title: "View History",
                systemImage: "clock.arrow.circlepath"
            ) {
                openWindow(id: WindowIDs.history)
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()
                .padding(.vertical, 2)

            MenuRow(
                title: "Quit ntfyme",
                systemImage: "power",
                shortcut: "⌘Q"
            ) { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }
}

// MARK: - Message Card

private struct MessageCard: View {
    let message: NtfyMessage
    let subscription: Subscription?
    let onClose: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.tint(for: message, subscription: subscription))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: Theme.symbol(for: message, subscription: subscription))
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Emoji.decorate(message.displayTitle, tags: message.tags))
                        .font(.system(size: 14, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let priorityIcon = Theme.priorityIcon(message.priorityLevel) {
                        Image(systemName: priorityIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.priorityTint(message.priorityLevel))
                            .help(Theme.priorityAccessibilityLabel(message.priorityLevel))
                    }
                    Spacer(minLength: 4)
                    Text(relativeTime)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 16, height: 16)
                            .background {
                                Circle()
                                    .fill(.secondary.opacity(hovering ? 0.25 : 0.12))
                            }
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss")
                }
                if !message.displayBody.isEmpty {
                    Text(message.displayBodyAttributed)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let attachment = message.attachment {
                    AttachmentView(attachment: attachment, token: subscription?.token, maxImageHeight: 140)
                        .padding(.top, 2)
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background.opacity(0.4))
        }
        .overlay {
            if !message.read {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { hovering = $0 }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.date, relativeTo: Date())
    }
}

// MARK: - Menu Row

private struct MenuRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    var shortcut: String? = nil
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16, alignment: .center)
                    .foregroundStyle(hovering ? .white : .primary)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(hovering ? .white : .primary)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 11))
                        .foregroundStyle(hovering ? .white.opacity(0.85) : .secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovering ? Color.accentColor : .clear)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct PopupListHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    StatusBarPopupView()
        .environmentObject(Store.shared)
}
