import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var store: Store
    @State private var search: String = ""
    @State private var topicFilter: UUID? = nil

    private var filteredMessages: [NtfyMessage] {
        store.messages.filter { msg in
            if let topicFilter, msg.subscriptionID != topicFilter { return false }
            if search.isEmpty { return true }
            let needle = search.lowercased()
            return msg.displayTitle.lowercased().contains(needle)
                || msg.displayBody.lowercased().contains(needle)
                || msg.topic.lowercased().contains(needle)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if filteredMessages.isEmpty {
                emptyState
            } else {
                messageList
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search messages", text: $search)
                .textFieldStyle(.plain)

            Picker("Topic", selection: $topicFilter) {
                Text("All topics").tag(UUID?.none)
                ForEach(store.subscriptions) { sub in
                    Text(sub.label).tag(UUID?.some(sub.id))
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Button {
                store.markAllRead()
            } label: {
                Label("Mark all read", systemImage: "envelope.open")
            }
            .disabled(store.unreadCount == 0)

            Button(role: .destructive) {
                store.clearMessages()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(store.messages.isEmpty)
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Group {
                if store.messages.isEmpty {
                    Text("No messages yet")
                } else {
                    Text("No matches")
                }
            }
            .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredMessages) { message in
                    HistoryRow(
                        message: message,
                        subscription: subscription(for: message),
                        topicLabel: topicLabel(for: message)
                    )
                    .onTapGesture {
                        store.markRead(message)
                        if let click = message.click, let url = URL(string: click) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    private func topicLabel(for message: NtfyMessage) -> String {
        subscription(for: message)?.label ?? message.topic
    }

    private func subscription(for message: NtfyMessage) -> Subscription? {
        guard let id = message.subscriptionID else { return nil }
        return store.subscriptions.first { $0.id == id }
    }
}

private struct HistoryRow: View {
    let message: NtfyMessage
    let subscription: Subscription?
    let topicLabel: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.tint(for: message, subscription: subscription))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: Theme.symbol(for: message, subscription: subscription))
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Emoji.decorate(message.displayTitle, tags: message.tags))
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(message.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                if !message.displayBody.isEmpty {
                    Text(message.displayBody)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .font(.system(size: 9))
                    Text(topicLabel)
                        .font(.system(size: 11))
                    let plain = Emoji.split(tags: message.tags).plain
                    if !plain.isEmpty {
                        Text(verbatim: "· " + plain.joined(separator: ", "))
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.background.opacity(0.5))
        }
        .overlay {
            if !message.read {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    HistoryView()
        .environmentObject(Store.shared)
}
