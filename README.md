# ntfyme

A native macOS menu bar client for [ntfy](https://ntfy.sh) — subscribe to topics, get system notifications, and keep a searchable history of everything that came in. No Electron, no helper binaries, just a small SwiftUI agent that lives in your menu bar.

> ntfyme is an independent client and is not affiliated with the [ntfy](https://github.com/binwiederhier/ntfy) project.

## Features

- **Menu bar agent** — runs as a `LSUIElement`, no Dock icon, no window clutter
- **Multiple subscriptions** — any topic on any ntfy server, with a per-topic server override and optional bearer token
- **Per-topic appearance** — pick an SF Symbol and a color for each subscription; falls back to smart heuristics from message tags when left on automatic
- **Native notifications** — banners via `UNUserNotificationCenter` with configurable sound (system default or one of 14 named macOS sounds), preview button included
- **Emoji tag prefix** — ntfy's `tags: ["test_tube"]` shorthand is translated to the matching emoji and prepended to the title, same as the iOS/Android/web clients
- **History window** — searchable, topic-filterable list of every notification you've ever received; survives restarts
- **Pause / resume** without unsubscribing — suppresses banners and sound, keeps the connection alive and the history rolling
- **Launch at login** via `SMAppService.mainApp` — no helper bundle, no entitlement scopes to manage
- **Localization-ready** — strings catalog (`Localizable.xcstrings`) shipping with English; language picker in Settings automatically lists whichever languages you translate the catalog into
- **App Sandbox + Hardened Runtime** enabled

## Screenshots

Drop screenshots into `docs/` and reference them here.

## Requirements

- macOS 14 or later (project deployment target is set higher; adjust in `ntfyme.xcodeproj` if you need to ship to older systems)
- Xcode 16 or later

## Build & run

```sh
git clone git@github.com:akandor/ntfyme.git
cd ntfyme
open ntfyme.xcodeproj
```

Hit ⌘R in Xcode, or build from the command line:

```sh
xcodebuild -project ntfyme.xcodeproj -scheme ntfyme -configuration Debug build
open "$(xcodebuild -project ntfyme.xcodeproj -scheme ntfyme -configuration Debug -showBuildSettings | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{print $2}')/ntfyme.app"
```

You'll need to substitute the `DEVELOPMENT_TEAM` in `ntfyme.xcodeproj/project.pbxproj` for your own Apple Developer Team ID, or set the target to use a personal team in the Xcode UI.

## Using it

1. Click the bell icon in the menu bar → **Settings…**
2. **General** — set your default ntfy server (defaults to `https://ntfy.sh`), pick a sound, decide whether ntfyme launches at login
3. **Subscriptions** → `+` — pick a topic, optionally override the server, optionally drop in a bearer token, optionally pick a custom icon and color
4. Send a test message from another machine:

   ```sh
   curl -H "Title: Hello from curl" \
        -H "Tags: tada,rocket" \
        -d "ntfyme is alive" \
        ntfy.sh/<your-topic>
   ```

The notification fires immediately and the popup picks up the new card.

## How notifications work

There's no APNs involvement. ntfyme holds a long-lived HTTP stream against `{server}/{topic}/json` for every subscription, reconnecting with exponential backoff if the connection drops. When a message arrives the running app posts a local `UNUserNotification` — the same mechanism the ntfy web client uses. The Push Notifications capability in your developer profile is **not** required.

This does mean the app has to be running to receive. The launch-at-login toggle handles the "after reboot" case; otherwise it lives quietly in the menu bar all day.

## Project layout

```
ntfyme/
├── ntfymeApp.swift          Scene wiring: MenuBarExtra, Settings, History window
├── ContentView.swift        Status bar popup
├── HistoryView.swift        Full history window
├── SettingsView.swift       General / Subscriptions / About tabs
├── Models.swift             Subscription, NtfyMessage
├── Store.swift              Persistence, stream lifecycle, preferences
├── NtfyClient.swift / inline streamLoop in Store.swift
├── NotificationService.swift   UNUserNotifications wrapper
├── Theme.swift              Icon/color palette and auto-detection heuristics
├── Emoji.swift              GitHub-style tag → emoji map
├── Localizable.xcstrings    String catalog (en, source)
├── Assets.xcassets/         Bell icon, ntfyme logo, accent color
└── AppIcon.icon             Icon Composer source for the app icon
```

State (subscriptions, messages, preferences) lives in `UserDefaults` inside the sandbox container.

## Contributing

Issues and PRs welcome. Larger changes — please open an issue first so we can talk about scope.

## License

MIT. See [LICENSE](LICENSE) (add one if you want to publish).
