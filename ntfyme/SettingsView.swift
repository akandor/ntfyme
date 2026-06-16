import SwiftUI
import AppKit

struct MainWindowView: View {
    @AppStorage(MainWindowTab.storageKey) private var selectedTab: String = MainWindowTab.general.rawValue

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(MainWindowTab.general.rawValue)
            SubscriptionsSettingsView()
                .tabItem { Label("Subscriptions", systemImage: "bell") }
                .tag(MainWindowTab.subscriptions.rawValue)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(MainWindowTab.history.rawValue)
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(MainWindowTab.about.rawValue)
        }
        .frame(minWidth: 720, minHeight: 480)
        // The app is launched with LSUIElement (agent, no Dock icon). When
        // the main window opens we flip the activation policy to .regular
        // so it gets a Dock icon, the application menu bar, and Cmd-Tab
        // visibility. When it disappears we go back to .accessory so
        // ntfyme drops out of the Dock again.
        .onAppear {
            // Promote to .regular first so the Dock registers a tile
            // for us, then push the icon image after a tick. The Dock
            // ignores applicationIconImage writes that happen before a
            // newly-promoted LSUIElement is in its tile list, which is
            // why the bare assignment in onAppear used to land blank.
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                if let icon = Self.resolveAppIcon() {
                    NSApp.applicationIconImage = icon
                }
            }
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    static func resolveAppIcon() -> NSImage? {
        AppIconResolver.resolve()
    }
}

// Try a few sources for the app icon. The Icon Composer .icon file
// compiles into Assets.car as a layered Tahoe icon, which the Dock
// sometimes refuses to flatten when the app was launched as an
// agent. The legacy AppIcon.icns also lives in Resources/, and
// NSWorkspace is a third independent path that goes through
// IconServices. Whichever one returns a non-empty NSImage first wins.
enum AppIconResolver {
    static func resolve() -> NSImage? {
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let img = NSImage(contentsOfFile: path),
           img.size != .zero {
            return img
        }
        let workspaceIcon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        if workspaceIcon.size != .zero {
            return workspaceIcon
        }
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        return nil
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject var store: Store
    @State private var serverDraft: String = ""
    @State private var showLanguageRestartAlert = false
    @State private var languageAtAppear: String = "system"

    var body: some View {
        Form {
            Section {
                TextField("Default server", text: $serverDraft, prompt: Text("https://ntfy.sh"))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commit)
                HStack {
                    Spacer()
                    Button("Apply") { commit() }
                        .disabled(normalizedDraft == store.defaultServer || normalizedDraft.isEmpty)
                }
            } header: {
                Text("Default server")
            } footer: {
                Text("Used for any subscription that doesn't override the server. Include scheme (https://).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { store.launchAtLogin },
                    set: { store.setLaunchAtLogin($0) }
                ))
            } header: {
                Text("Startup")
            } footer: {
                Text("Open ntfyme automatically when you log in to your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Language", selection: $store.language) {
                    ForEach(Store.availableLanguages, id: \.code) { lang in
                        if lang.code == "system" {
                            Text("System default").tag(lang.code)
                        } else {
                            Text(verbatim: lang.displayName).tag(lang.code)
                        }
                    }
                }
            } header: {
                Text("Language")
            } footer: {
                Text("Restart ntfyme to apply a new language.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Play sound for new notifications", isOn: $store.soundEnabled)

                HStack {
                    Picker("Sound", selection: $store.soundName) {
                        ForEach(Store.availableSounds, id: \.self) { name in
                            if name == "default" {
                                Text("System default").tag(name)
                            } else {
                                Text(verbatim: name).tag(name)
                            }
                        }
                    }
                    .disabled(!store.soundEnabled)

                    Button {
                        NotificationService.shared.previewSound(named: store.soundName)
                    } label: {
                        Image(systemName: "play.circle")
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(!store.soundEnabled || store.soundName == "default")
                    .help("Play a preview of this sound")
                }
            } header: {
                Text("Sound")
            } footer: {
                Text("\"System default\" follows the macOS notification sound and respects Do Not Disturb. Named sounds play directly and will be heard even while a Focus mode is active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Use a different sound for high-priority messages", isOn: $store.highPrioritySoundEnabled)
                    .disabled(!store.soundEnabled)

                HStack {
                    Picker("Sound", selection: $store.highPrioritySoundName) {
                        ForEach(Store.availableSounds, id: \.self) { name in
                            if name == "default" {
                                Text("System default").tag(name)
                            } else {
                                Text(verbatim: name).tag(name)
                            }
                        }
                    }
                    .disabled(!store.soundEnabled || !store.highPrioritySoundEnabled)

                    Button {
                        NotificationService.shared.previewSound(named: store.highPrioritySoundName)
                    } label: {
                        Image(systemName: "play.circle")
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(!store.soundEnabled || !store.highPrioritySoundEnabled || store.highPrioritySoundName == "default")
                    .help("Play a preview of this sound")
                }
            } header: {
                Text("High-priority sound")
            } footer: {
                Text("Played for messages with priority High (4) or Max (5). Lower priorities use the sound chosen above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    Self.openNotificationSettings()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.slash")
                        Text("Open notification settings")
                    }
                }
            } header: {
                Text("Notification icon")
            } footer: {
                Text("If the notification banners or the entry in System Settings → Notifications show a blank icon, open the notification settings, find ntfyme, and toggle Allow Notifications off and back on. The system re-caches the app's icon at that moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            serverDraft = store.defaultServer
            languageAtAppear = store.language
        }
        .onChange(of: store.language) { _, newValue in
            if newValue != languageAtAppear {
                showLanguageRestartAlert = true
            }
        }
        .alert("Language change", isPresented: $showLanguageRestartAlert) {
            Button("Restart Now") { Self.relaunch() }
            Button("Later", role: .cancel) { languageAtAppear = store.language }
        } message: {
            Text("ntfyme needs to restart to switch languages.")
        }
    }

    private static func openNotificationSettings() {
        // Deep-link to System Settings → Notifications. macOS 13+
        // accepts this URL scheme; the per-app anchor below it works
        // on most Tahoe builds but silently falls through to the
        // section header on others, which is still where the user
        // needs to be.
        let urls = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.toepper.rocks.ntfyme",
            "x-apple.systempreferences:com.apple.preference.notifications?id=com.toepper.rocks.ntfyme",
            "x-apple.systempreferences:com.apple.preference.notifications"
        ]
        for raw in urls {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private static func relaunch() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    private var normalizedDraft: String {
        serverDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commit() {
        let value = normalizedDraft
        guard !value.isEmpty, URL(string: value) != nil else { return }
        store.defaultServer = value
    }
}

// MARK: - Subscriptions

struct SubscriptionsSettingsView: View {
    @EnvironmentObject var store: Store
    @State private var selection: UUID?
    @State private var editing: Subscription?
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(store.subscriptions) { sub in
                    SubscriptionRow(sub: sub, defaultServer: store.defaultServer)
                        .tag(sub.id)
                        // Use an AppKit NSClickGestureRecognizer overlay
                        // (rather than SwiftUI's TapGesture) so single
                        // clicks pass straight through to NSTableView's
                        // selection logic, matching Finder/Mail.app
                        // behavior. SwiftUI's TapGesture(count:) blocks
                        // single clicks while waiting to recognize a
                        // double-click; NSClickGestureRecognizer with
                        // delaysPrimaryMouseButtonEvents = false does
                        // not.
                        .overlay(
                            DoubleClickCatcher { editing = sub }
                                .allowsHitTesting(true)
                        )
                        .contextMenu {
                            Button("Edit…") { editing = sub }
                            Button("Send test message") { store.sendTestMessage(sub) }
                            Divider()
                            Button("Remove", role: .destructive) { store.removeSubscription(sub) }
                        }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            HStack(spacing: 2) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .help("Subscribe to a new topic")

                Button {
                    guard let id = selection,
                          let sub = store.subscriptions.first(where: { $0.id == id }) else { return }
                    store.removeSubscription(sub)
                    selection = nil
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .disabled(selection == nil)
                .help("Unsubscribe from the selected topic")

                Button {
                    guard let id = selection,
                          let sub = store.subscriptions.first(where: { $0.id == id }) else { return }
                    editing = sub
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .disabled(selection == nil)
                .help("Edit the selected subscription")

                Button {
                    guard let id = selection,
                          let sub = store.subscriptions.first(where: { $0.id == id }) else { return }
                    store.sendTestMessage(sub)
                } label: {
                    Image(systemName: "paperplane")
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .disabled(selection == nil)
                .help("Send a test notification to the selected topic")

                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(8)
        }
        .sheet(isPresented: $showingAdd) {
            SubscriptionEditor(
                existing: nil,
                defaultServer: store.defaultServer
            ) { newSub in
                store.addSubscription(newSub)
            }
        }
        .sheet(item: $editing) { sub in
            SubscriptionEditor(
                existing: sub,
                defaultServer: store.defaultServer
            ) { updated in
                store.updateSubscription(updated)
            }
        }
    }
}

private struct SubscriptionRow: View {
    let sub: Subscription
    let defaultServer: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.tint(for: sub))
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: Theme.symbol(for: sub))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.label)
                    .font(.system(size: 13, weight: .medium))
                HStack(spacing: 6) {
                    Text(sub.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if sub.serverURL != nil, !sub.serverURL!.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(sub.effectiveServer(default: defaultServer))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

private struct SubscriptionEditor: View {
    let existing: Subscription?
    let defaultServer: String
    let onSave: (Subscription) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var topic: String = ""
    @State private var displayName: String = ""
    @State private var useCustomServer: Bool = false
    @State private var server: String = ""
    @State private var token: String = ""
    @State private var iconName: String? = nil
    @State private var colorName: String? = nil

    private var canSave: Bool {
        let t = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        if useCustomServer {
            let s = server.trimmingCharacters(in: .whitespacesAndNewlines)
            return !s.isEmpty && URL(string: s) != nil
        }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(existing == nil ? "Subscribe to a topic" : "Edit subscription")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Form {
                Section {
                    TextField("Topic", text: $topic, prompt: Text("e.g. alerts"))
                    TextField("Display name (optional)", text: $displayName)
                }

                Section {
                    Toggle("Use a different server for this topic", isOn: $useCustomServer)
                    if useCustomServer {
                        TextField("Server", text: $server, prompt: Text("https://ntfy.example.com"))
                    } else {
                        HStack {
                            Text("Server")
                            Spacer()
                            Text(defaultServer)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    SecureField("Access token (optional)", text: $token)
                } footer: {
                    Text("Used for protected topics. Sent as Bearer token.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    AppearancePreviewRow(iconName: iconName, colorName: colorName)
                    ColorPickerStrip(selection: $colorName)
                    IconPickerStrip(selection: $iconName)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Shown next to messages from this topic in the popup and history. Choose “Automatic” to derive the look from message tags.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(existing == nil ? "Subscribe" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
            .padding(16)
        }
        .frame(width: 460)
        .onAppear { load() }
    }

    private func load() {
        guard let existing else { return }
        topic = existing.topic
        displayName = existing.displayName ?? ""
        if let s = existing.serverURL, !s.isEmpty {
            useCustomServer = true
            server = s
        }
        token = existing.token ?? ""
        iconName = existing.iconName
        colorName = existing.colorName
    }

    private func save() {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        let sub = Subscription(
            id: existing?.id ?? UUID(),
            topic: trimmedTopic,
            serverURL: useCustomServer ? trimmedServer : nil,
            token: trimmedToken.isEmpty ? nil : trimmedToken,
            displayName: trimmedName.isEmpty ? nil : trimmedName,
            iconName: iconName,
            colorName: colorName
        )
        onSave(sub)
        dismiss()
    }
}

// MARK: - Appearance pickers

private struct AppearancePreviewRow: View {
    let iconName: String?
    let colorName: String?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(resolvedColor)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: iconName ?? "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text("Preview")
                    .font(.system(size: 12, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var resolvedColor: Color {
        if let name = colorName, let c = Theme.color(named: name) { return c }
        return .gray
    }

    private var subtitle: LocalizedStringKey {
        if iconName == nil && colorName == nil { return "Automatic from message tags" }
        if iconName == nil { return "Custom color, automatic icon" }
        if colorName == nil { return "Custom icon, automatic color" }
        return "Custom icon and color"
    }
}

private struct ColorPickerStrip: View {
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Color")
                .font(.system(size: 12, weight: .semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    AutomaticSwatch(isSelected: selection == nil) {
                        selection = nil
                    }
                    ForEach(Theme.availableColors, id: \.name) { item in
                        Circle()
                            .fill(item.color)
                            .frame(width: 26, height: 26)
                            .overlay {
                                if selection == item.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.primary.opacity(selection == item.name ? 0.35 : 0), lineWidth: 1.5)
                            }
                            .onTapGesture { selection = item.name }
                            .help(item.name.capitalized)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct IconPickerStrip: View {
    @Binding var selection: String?

    private let columns = [GridItem(.adaptive(minimum: 36, maximum: 36), spacing: 6)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Icon")
                .font(.system(size: 12, weight: .semibold))
            LazyVGrid(columns: columns, spacing: 6) {
                AutomaticTile(isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(Theme.availableIcons, id: \.self) { name in
                    Button {
                        selection = name
                    } label: {
                        Image(systemName: name)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(selection == name ? Color.accentColor : Color.secondary.opacity(0.12))
                            }
                            .foregroundStyle(selection == name ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .help(name)
                }
            }
        }
    }
}

private struct AutomaticSwatch: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                .overlay {
                    Circle()
                        .strokeBorder(Color.primary.opacity(isSelected ? 0.35 : 0), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .help("Automatic")
    }
}

private struct AutomaticTile: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .help("Automatic")
    }
}

// MARK: - About

struct AboutSettingsView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 12)

            Image("ntfyme")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(.tint)

            Text("ntfyme")
                .font(.system(size: 24, weight: .bold))

            Text(version)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("A native macOS menu bar client for ntfy brought to you by Toepper.Rocks.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://toepper.rocks")!) {
                    Label("toepper.rocks", systemImage: "link")
                }
                Link(destination: URL(string: "https://github.com/akandor/ntfyme")!) {
                    Label("ntfyme on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            .font(.callout)
            
            HStack(spacing: 16) {
                Link(destination: URL(string: "https://ntfy.sh")!) {
                    Label("ntfy.sh", systemImage: "link")
                }
                Link(destination: URL(string: "https://github.com/binwiederhier/ntfy")!) {
                    Label("ntfy on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            .font(.callout)

            Spacer()

            Text("ntfyme is not affiliated with the ntfy project.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Double-click recognizer

// An AppKit NSClickGestureRecognizer wrapped as a SwiftUI view.
// Used to add Mail.app-style double-click without stealing single-click
// selection from the host List. delaysPrimaryMouseButtonEvents = false
// lets the underlying NSTableView keep processing single clicks while
// this recognizer waits for a possible second click.
private struct DoubleClickCatcher: NSViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let recognizer = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        recognizer.numberOfClicksRequired = 2
        recognizer.delaysPrimaryMouseButtonEvents = false
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func handle(_ sender: NSClickGestureRecognizer) { action() }
    }
}

#Preview {
    MainWindowView()
        .environmentObject(Store.shared)
}
