# ntfyme

A native macOS menu bar client for [ntfy](https://ntfy.sh) — subscribe to topics, get system notifications, and keep a searchable history of everything that came in. No Electron, no helper binaries, just a small SwiftUI agent that lives in your menu bar.

> ntfyme is an independent client and is not affiliated with the [ntfy](https://github.com/binwiederhier/ntfy) project.

## Features

- **Menu bar agent** — runs as a `LSUIElement`, no Dock icon, no window clutter
- **Multiple subscriptions** — any topic on any ntfy server, with a per-topic server override and optional bearer token
- **Per-topic appearance** — pick an SF Symbol and a color for each subscription; falls back to smart heuristics from message tags when left on automatic
- **Native notifications** with sound control:
  - Configurable sound (system default or one of 14 named macOS sounds) with a preview button
  - **Separate sound for high-priority messages** (priority 4 or 5) so you can pick something louder/distinctive for things that actually need attention
- **Priority indicators** — ntfy's 1–5 priorities are rendered as colored chevrons next to the title (red double-up for Max, single-up for High, hidden for Default, grey down for Low / double-down for Min)
- **Emoji tag prefix** — ntfy's `tags: ["test_tube"]` shorthand is translated to the matching emoji and prepended to the title, same as the iOS/Android/web clients
- **Attachments** — image attachments render as inline thumbnails, everything else as a tappable paperclip chip with filename + size; bearer tokens are forwarded so previews and downloads work on protected topics
- **Clickable URLs in message bodies** — `NSDataDetector` runs over the body and turns URLs into accent-colored, underlined links opened by the system handler
- **Scrollable popup** — the popup sizes to its content and starts scrolling at 420pt, so a flood of messages stays readable without pushing the menu off-screen
- **History window** — searchable, topic-filterable list of every notification you've ever received; survives restarts
- **Pause / resume** without unsubscribing — suppresses banners and sound, keeps the connection alive and the history rolling
- **Launch at login** via `SMAppService.mainApp` — no helper bundle, no entitlement scopes to manage
- **Localization-ready** — strings catalog (`Localizable.xcstrings`) shipping with English; the language picker in Settings automatically lists whichever languages you've translated the catalog into, with a restart prompt so the change takes effect cleanly
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
2. **General** — set your default ntfy server (defaults to `https://ntfy.sh`), pick a default sound and (optionally) a louder one for High/Max priority, pick the UI language, decide whether ntfyme launches at login
3. **Subscriptions** → `+` — pick a topic, optionally override the server, optionally drop in a bearer token, optionally pick a custom icon and color
4. **About** — version info and links to the upstream ntfy project
5. Send a test message from another machine:

   ```sh
   # Plain
   curl -H "Title: Hello from curl" \
        -H "Tags: tada,rocket" \
        -d "ntfyme is alive — https://ntfy.sh/docs" \
        ntfy.sh/<your-topic>

   # High priority — uses the alternate sound if you enabled one
   curl -H "Priority: 5" -d "kitchen on fire" ntfy.sh/<your-topic>

   # With an image attachment
   curl -H "Attach: https://placecats.com/400/300" \
        -d "cat" \
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
├── ContentView.swift        Status bar popup (with scrollable measured-height card list)
├── HistoryView.swift        Full history window
├── SettingsView.swift       General / Subscriptions / About tabs
├── AttachmentView.swift     Image thumbnails + paperclip chips, auth-aware download
├── Models.swift             Subscription, NtfyMessage, NtfyAttachment, PriorityLevel
├── Store.swift              Persistence, stream lifecycle, preferences
├── NotificationService.swift   UNUserNotifications wrapper
├── Theme.swift              Icon/color palette, priority chevron, auto-detection heuristics
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
