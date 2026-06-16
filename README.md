# ntfyme

A native macOS menu bar client for [ntfy](https://ntfy.sh) — subscribe to topics, get system notifications, and keep a searchable history of everything that came in. No Electron, no helper binaries, just a small SwiftUI agent that lives in your menu bar.

> ntfyme is an independent client and is not affiliated with the [ntfy](https://github.com/binwiederhier/ntfy) project.

## Features

- **Menu bar agent** — runs as a `LSUIElement`, no Dock icon by default. The bell shows a small red dot when there's something new, plus a colored connection status pip (green/orange/red) for stream health.
- **Multiple subscriptions** — any topic on any ntfy server, with a per-topic server override and optional bearer token.
- **Per-topic appearance** — pick an SF Symbol and a color for each subscription; falls back to smart heuristics from message tags when left on automatic.
- **Per-subscription test message** — Settings → Subscriptions has a paper-plane button (and a context-menu action) that publishes a canned notification to the selected topic via the configured server and token, so you can verify the whole round-trip in one click.
- **Replay on reconnect** — every stream remembers the id of the last message it saw and asks the server for `?since=<id>` on every reconnect, so a Mac that slept overnight backfills missed messages into the popup and history when it wakes (replayed messages don't re-fire notifications — they're detected and added silently).
- **Connection indicator** — the popup header shows an aggregated dot — green when every subscription is connected, orange when some are mid-reconnect, red when everything is offline — with a hover tooltip listing how many topics are live.
- **Combined main window** — one window with **General / Subscriptions / History / About** tabs, opened from the popup. Promotes ntfyme from a menu-bar agent to a regular Dock-icon-bearing app while the window is up, then drops back to agent mode when closed.
- **Native notifications** with sound control:
  - Configurable sound (system default or one of 14 named macOS sounds) with a preview button
  - **Separate sound for high-priority messages** (priority 4 or 5) so you can pick something louder/distinctive for things that actually need attention
- **Priority indicators** — ntfy's 1–5 priorities are rendered as colored chevrons next to the title (red double-up for Max, single-up for High, hidden for Default, grey down for Low / double-down for Min).
- **Emoji tag prefix** — ntfy's `tags: ["test_tube"]` shorthand is translated to the matching emoji and prepended to the title, same as the iOS/Android/web clients.
- **Attachments** — image attachments render as inline thumbnails, everything else as a tappable paperclip chip with filename + size; bearer tokens are forwarded so previews and downloads work on protected topics.
- **Clickable URLs in message bodies** — `NSDataDetector` runs over the body and turns URLs into accent-colored, underlined links opened by the system handler.
- **Scrollable popup** — the popup measures its content and starts scrolling at 420pt, so a flood of messages stays readable without pushing the menu off-screen.
- **History window** — searchable, topic-filterable list of every notification you've ever received; survives restarts. Search and filters live in the native window toolbar.
- **Pause / resume** without unsubscribing — suppresses banners and sound, keeps the connection alive and the history rolling.
- **Launch at login** via `SMAppService.mainApp` — no helper bundle, no entitlement scopes to manage.
- **Liquid Glass popup on macOS 26 (Tahoe)** — the menu bar popup opts into the new `glassEffect` material when available; older macOS falls back to a regular material via an availability check.
- **Localized** — strings catalog (`Localizable.xcstrings`) ships with **English**, **German**, **French**, **Spanish**, **Italian**, **Portuguese (Brazil)**, and **Japanese**; the language picker in Settings lists whichever localizations the bundle has and prompts to restart so the change takes effect cleanly.
- **App Sandbox + Hardened Runtime** enabled. The only network destination is the ntfy server(s) you configure.

## Screenshots

Drop screenshots into `docs/` and reference them here.

## Requirements

- macOS 26 (Tahoe) — the project deployment target is set to 26.5 to opt into Liquid Glass APIs. Drop the target in `ntfyme.xcodeproj` if you need to ship to Sequoia or older; the `glassEffect` call is already wrapped in `#available`.
- Xcode 26 or later

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
2. **General** — set your default ntfy server (defaults to `https://ntfy.sh`), pick a default sound and (optionally) a louder one for High/Max priority, pick the UI language, decide whether ntfyme launches at login.
3. **Subscriptions** → `+` — pick a topic, optionally override the server, optionally drop in a bearer token, optionally pick a custom icon and color. The paper-plane button (or right-click → "Send test message") publishes a canned notification through the topic so you can confirm it arrives.
4. **About** — version info and links to the upstream ntfy project.
5. Or send a test message from another machine:

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

System sounds are played through `AVAudioPlayer` reading the files in `/System/Library/Sounds/` directly. `NSSound.play()` would be shorter, but on the App Sandbox it triggers `AudioAnalytics` which mach-looks up a service the sandbox doesn't grant; the resulting precondition crashes the process.

## Notification icon caching

macOS's user-notifications subsystem (`usernoted`) snapshots the bundle's icon the **first time** the user grants notification authorization, then reuses that image for every banner and the System Settings → Notifications row forever after. There's no public API to invalidate this — `tccutil reset Notifications <bundle>` doesn't apply because notifications aren't tracked in the TCC database. ntfyme handles this two ways:

- On every launch, the app icon is assigned to `NSApplication.shared.applicationIconImage` *before* the auth request fires, so fresh installs (and TestFlight users who haven't tapped Allow yet) get the correct image cached at the source.
- If you ever do end up with a blank notification icon (e.g. you ran an older build that didn't have this fix), Settings → General has an **Open notification settings** button that deep-links you to the right page. Toggle Allow Notifications off and back on; the system re-snapshots the bundle's icon at that moment.

## Localization

Translations live in `ntfyme/Localizable.xcstrings`. Add a language by opening it in Xcode → click `+` at the bottom-left → pick the locale → fill in the cells. The language picker in Settings reads `Bundle.main.localizations` so anything you add appears automatically — no code change needed.

The two patterns to watch for when adding new user-facing strings:

- `Text("literal")` and `Label("literal", systemImage: …)` flow through the catalog automatically (they pick the `LocalizedStringKey` initializer).
- `Text(stringVariable)` does **not** localize. If a function takes a `String` and renders it as text, change the parameter to `LocalizedStringKey`, or branch ternary expressions into `if/else` so each literal keeps its key inference. The same applies to `MenuRow.title`, `emptyState(title:subtitle:)` and similar helpers.

## App Store distribution

[APPSTORE.md](APPSTORE.md) has ASCII-clean copies of the App Store Connect fields (description, keywords, what's new, screenshots checklist, App Review notes, privacy answers). The description and What's New use ASCII bullets and quotes because App Store Connect's "invalid characters" validator rejects `•`, em dashes, and curly quotes on submission.

## Project layout

```
ntfyme/
├── ntfymeApp.swift          Scene wiring: MenuBarExtra + unified Window with
│                            MainWindowView tabs; LSUIElement→.regular toggle
├── ContentView.swift        Status bar popup (scrollable measured-height card list,
│                            GlassBackground modifier with macOS 26 availability,
│                            ConnectionIndicator dot in the header)
├── HistoryView.swift        History tab content; search + filters in the native toolbar
├── SettingsView.swift       MainWindowView (General/Subscriptions/History/About),
│                            AppIconResolver, DoubleClickCatcher (NSClickGestureRecognizer)
├── AttachmentView.swift     Image thumbnails + paperclip chips, auth-aware fetch + download
├── Models.swift             Subscription, NtfyMessage, NtfyAttachment, PriorityLevel,
│                            attributed body with NSDataDetector links
├── Store.swift              Persistence, stream lifecycle (with ?since= replay and
│                            ConnectionState), preferences, test-message publish
├── NotificationService.swift   UNUserNotifications + AVAudioPlayer-backed system sounds
├── Theme.swift              Icon/color palette, priority chevron, auto-detection heuristics
├── Emoji.swift              GitHub-style tag → emoji map
├── Localizable.xcstrings    String catalog (en source + de/fr/es/it/ja/pt-BR translations)
├── Assets.xcassets/         Bell icon, ntfyme logo, accent color
└── AppIcon.icon             Icon Composer source for the app icon
```

State (subscriptions, messages, preferences) lives in `UserDefaults` inside the sandbox container.

## Contributing

Issues and PRs welcome. Larger changes — please open an issue first so we can talk about scope.

## License

MIT. See [LICENSE](LICENSE) (add one if you want to publish).
