import SwiftUI
import AppKit

@main
struct ntfymeApp: App {
    @StateObject private var store = Store.shared

    init() {
        // Apply the saved language override before Bundle loads any
        // localized resources. Setting AppleLanguages after the bundle has
        // resolved its preferred localization is too late — the new value
        // only takes effect on the next launch.
        let saved = UserDefaults.standard.string(forKey: "language") ?? "system"
        Store.applyLanguageOverride(saved)

        // Hand AppKit the bundle icon BEFORE we trigger the notification
        // authorization prompt. The user-notifications subsystem
        // snapshots the bundle's icon at first authorization and reuses
        // that cached image for every banner and the System Settings →
        // Notifications row forever after, so getting it right at this
        // moment matters for new installs.
        if let icon = AppIconResolver.resolve() {
            NSApplication.shared.applicationIconImage = icon
        }

        Task { @MainActor in
            await NotificationService.shared.requestAuthorizationIfNeeded()
            Store.shared.startAll()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            StatusBarPopupView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(showsDot: showsUnreadDot)
        }
        .menuBarExtraStyle(.window)

        Window("ntfyme", id: WindowIDs.main) {
            MainWindowView()
                .environmentObject(store)
        }
        .defaultSize(width: 820, height: 560)
    }

    private var showsUnreadDot: Bool {
        !store.notificationsPaused && store.unreadCount > 0
    }
}

enum WindowIDs {
    static let main = "main"
}

enum MainWindowTab: String {
    case general, subscriptions, history, about

    /// UserDefaults key the popup writes before calling openWindow, so the
    /// window's @AppStorage-backed selection switches to the right tab.
    static let storageKey = "mainWindowTab"
}

// We hand SwiftUI a pre-sized NSImage rather than Image("bell") with
// .frame() modifiers, because MenuBarExtra reads the image's intrinsic
// size for menu-bar layout and ignores SwiftUI frame constraints —
// leaving a .resizable() SVG to render at its full viewBox size and
// overflow the menu bar.
//
// The unread dot is composited into the NSImage rather than added as a
// SwiftUI .overlay — overlays inside MenuBarExtra labels don't render
// reliably. Compositing means the bell can't stay a template image
// (templates are monochrome and would recolor the red dot), so we bake
// in NSColor.labelColor at draw time and re-render on appearance
// changes via @Environment(\.colorScheme).
private struct MenuBarLabel: View {
    let showsDot: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(nsImage: composedImage())
    }

    private func composedImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        guard let bell = NSImage(named: "ntfyme") else { return NSImage() }
        bell.size = size

        if !showsDot {
            bell.isTemplate = true
            return bell
        }

        let composite = NSImage(size: size)
        composite.lockFocus()
        defer { composite.unlockFocus() }

        bell.draw(in: NSRect(origin: .zero, size: size),
                  from: .zero,
                  operation: .sourceOver,
                  fraction: 1.0)

        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.setBlendMode(.sourceIn)
            NSColor.labelColor.setFill()
            NSRect(origin: .zero, size: size).fill()
            ctx.setBlendMode(.normal)
        }

        let dotSize: CGFloat = 6
        let dotRect = NSRect(
            x: size.width - dotSize - 0.5,
            y: size.height - dotSize - 0.5,
            width: dotSize,
            height: dotSize
        )
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: dotRect).fill()

        composite.isTemplate = false
        return composite
    }
}
