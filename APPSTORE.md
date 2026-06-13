# App Store listing — ntfyme

Copy/paste-ready content for App Store Connect. Character limits noted next to each field.

---

## Identity

| Field | Value |
| --- | --- |
| **Name** (30) | ntfyme |
| **Subtitle** (30) | Notifications from ntfy |
| **Bundle ID** | `com.toepper.rocks.ntfyme` |
| **SKU** | `ntfyme-macos` |
| **Primary Category** | Utilities |
| **Secondary Category** | Developer Tools |
| **Copyright** | © 2026 Toepper.Rocks |

---

## Promotional Text (170)

Native macOS menu bar client for ntfy. Subscribe to topics, get rich notifications with sound, priority, attachments, and an emoji-tagged title — all from your menu bar.

---

## Description (<= 4000)

ASCII-only. Pastes cleanly into App Store Connect.

```
ntfyme is a native macOS menu bar client for ntfy (https://ntfy.sh), the simple, self-hostable HTTP-based pub/sub notification service. It lives quietly in your menu bar, holds a streaming connection to every topic you subscribe to, and turns each message into a proper macOS notification with sound, an inline thumbnail, and an attached file when present.

No Electron, no bundled web view, no helper binaries. Just a small native SwiftUI app for macOS.

KEY FEATURES

- Menu bar agent: no Dock icon, no window clutter. A bell with a red dot tells you when something new arrived.

- Multi-topic subscriptions: subscribe to any topic on ntfy.sh, on your own self-hosted ntfy server, or a mix. Each subscription can use its own server and bearer token.

- Per-topic appearance: pick an icon and color for each subscription so messages from your backups, your home automation, and your CI all look distinct in the popup and history.

- Rich notifications: title, body, priority chevrons (Max and High in red, Low and Min in grey), and emoji prefixes derived from ntfy's tag shorthand. Clickable URLs in message bodies are detected automatically.

- Attachments: image attachments appear as inline thumbnails right in the popup and history. Other files show as a paperclip chip with filename and size; click to open. Bearer tokens are forwarded so previews and downloads work on protected topics.

- Configurable sound: pick the system default or one of fourteen named macOS sounds, with a preview button. Optionally set a separate, more attention-grabbing sound for High and Max priority messages.

- Searchable history: every notification you have received, filterable by topic and searchable by text. Survives restarts.

- Pause and resume notifications without unsubscribing: your topics stay connected and the history keeps building; you just stop being interrupted.

- Launch at login: opt in from Settings and ntfyme is back in your menu bar after every reboot.

- Localized: Settings includes a language picker. Ships with English; more languages added as translations land.

- Privacy by design: runs in the macOS App Sandbox. No analytics, no tracking, no third-party SDKs. The only network connection is to the ntfy server(s) you configure.

HOW IT WORKS

ntfyme connects to {server}/{topic}/json for each subscription and reads messages off a long-lived HTTP stream, the same mechanism the official ntfy web client uses. When a message arrives the app posts a local notification. macOS Push Notifications and APNs are NOT involved.

This means the app must be running to receive. Launch at Login covers that. Battery and bandwidth use are negligible since idle streams cost almost nothing.

ntfyme is an independent client and is not affiliated with the ntfy project.
```

---

## Keywords (100, comma-separated, no spaces around commas)

```
ntfy,notification,notifications,push,menubar,statusbar,alerts,webhook,pubsub,selfhosted,homelab,monitoring
```

(96 chars — fits.)

---

## What's New (release notes, <= 4000)

ASCII-only.

```
1.0

First release of ntfyme.

- Subscribe to topics on ntfy.sh or any self-hosted ntfy server
- Native macOS notifications with sound, priority, and emoji-prefixed titles
- Per-topic server, bearer token, icon, and color
- Inline image attachment thumbnails; paperclip chips for other files
- Clickable URLs in message bodies
- Searchable, topic-filterable history window
- Pause and resume notifications
- Separate sound for High and Max priority messages
- Launch at Login
- English and German translations
```

---

## Support URLs

> Replace these before submitting.

| Field | URL |
| --- | --- |
| **Support URL** (required) | `https://toepper.rocks/ntfyme/support` |
| **Marketing URL** (optional) | `https://toepper.rocks/ntfyme` |
| **Privacy Policy URL** (required) | `https://toepper.rocks/ntfyme/privacy` |
| **Source code** (optional) | `https://github.com/akandor/ntfyme` |

---

## App Privacy

App Store Connect → App Privacy. The honest answer for ntfyme:

- **Data collection**: None.
- **Tracking**: None.
- **Third-party SDKs**: None.
- **Account creation required**: No.

Recommended privacy questionnaire answers:

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | **No** |
| Does this app use third-party tracking? | **No** |

Privacy policy text (suggested, place at the Privacy Policy URL):

> ntfyme does not collect, store, or transmit any personal data. The app connects only to the ntfy server(s) you configure in Settings; no other network connections are made. Subscriptions, message history, and preferences are stored locally in the macOS App Sandbox and never leave your Mac. There are no analytics, no telemetry, and no third-party SDKs.

---

## Age Rating

- **Suggested**: 4+
- **Unrestricted Web Access**: No (the app fetches attachments from servers the user explicitly subscribes to; it does not embed a web browser).

---

## Screenshots & previews

macOS App Store requires at least one screenshot per supported size. Take them at 2560×1600 (16:10) or use the standard Apple frame templates.

Recommended shots:

1. **Menu bar popup with messages and a red unread dot** — primary marketing image.
2. **History window** showing messages with priorities, tags, and an attachment thumbnail.
3. **Settings → Subscriptions** showing the icon + color pickers for a topic.
4. **Settings → General** showing the sound picker and "Launch at login".
5. **A notification banner** triggered by a `curl` call (top-right of screen).

App Preview video (optional, ≤ 30 s): pop the menu bar item open, scroll the message list, click into Settings, switch to the History window, dismiss a notification. No audio required.

---

## Build / archive checklist

Before uploading to App Store Connect:

- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped in `ntfyme.xcodeproj/project.pbxproj`
- Distribution-signed archive built via Xcode → Product → Archive
- Hardened Runtime enabled (already on)
- App Sandbox entitlement matches what we ship (`com.apple.security.app-sandbox`, `com.apple.security.network.client`)
- Icon Composer source (`ntfyme/AppIcon.icon`) renders cleanly at every macOS-required size
- TestFlight build sent to internal testers before public release

---

## App Review Information (notes for the reviewer)

> Paste into the App Review Notes field.

ntfyme is a client for ntfy (https://ntfy.sh), an HTTP-based pub/sub notification service. To test:

1. Open Settings → Subscriptions → "+" and add the topic `ntfyme-review-<random>` on the default server `https://ntfy.sh`.
2. From any terminal: `curl -d "review test" ntfy.sh/ntfyme-review-<random>`
3. A macOS notification should appear within a second, with the message visible in the menu bar popup and the History window.

No account or login is required. Public ntfy.sh topics are not authenticated.
