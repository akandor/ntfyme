# Graph Report - .  (2026-07-06)

## Corpus Check
- Corpus is ~12,111 words - fits in a single context window. You may not need a graph.

## Summary
- 303 nodes · 516 edges · 20 communities (19 shown, 1 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.87)
- Token cost: 180,950 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Settings & Main Window UI|Settings & Main Window UI]]
- [[_COMMUNITY_Store & Persistence|Store & Persistence]]
- [[_COMMUNITY_Message Models|Message Models]]
- [[_COMMUNITY_Menu Bar Popup|Menu Bar Popup]]
- [[_COMMUNITY_App Lifecycle & Design Concepts|App Lifecycle & Design Concepts]]
- [[_COMMUNITY_Notification Delivery|Notification Delivery]]
- [[_COMMUNITY_Attachment Rendering|Attachment Rendering]]
- [[_COMMUNITY_Emoji & History View|Emoji & History View]]
- [[_COMMUNITY_Message Coding Keys|Message Coding Keys]]
- [[_COMMUNITY_Theme & Priority Styling|Theme & Priority Styling]]
- [[_COMMUNITY_Icon Composer Config|Icon Composer Config]]
- [[_COMMUNITY_Connection State Enums|Connection State Enums]]
- [[_COMMUNITY_Terminal Glyph Concepts|Terminal Glyph Concepts]]
- [[_COMMUNITY_Bell Icon Concepts|Bell Icon Concepts]]
- [[_COMMUNITY_Asset Catalog Metadata A|Asset Catalog Metadata A]]
- [[_COMMUNITY_Asset Catalog Metadata B|Asset Catalog Metadata B]]
- [[_COMMUNITY_ntfyme Logo Concepts|ntfyme Logo Concepts]]
- [[_COMMUNITY_Accent Color Asset|Accent Color Asset]]
- [[_COMMUNITY_Asset Catalog Root|Asset Catalog Root]]
- [[_COMMUNITY_Graphify Workflow Instructions|Graphify Workflow Instructions]]

## God Nodes (most connected - your core abstractions)
1. `Store` - 43 edges
2. `NtfyMessage` - 21 edges
3. `StatusBarPopupView` - 18 edges
4. `Theme` - 18 edges
5. `Subscription` - 16 edges
6. `CodingKeys` - 16 edges
7. `ntfymeApp` - 16 edges
8. `MessageCard` - 13 edges
9. `NtfyAttachment` - 12 edges
10. `NotificationService` - 12 edges

## Surprising Connections (you probably didn't know these)
- `ntfyme (README)` --references--> `Store`  [INFERRED]
  README.md → ntfyme/Store.swift
- `ntfyme (README)` --references--> `Liquid Glass availability gating`  [EXTRACTED]
  README.md → ntfyme/ContentView.swift
- `ntfyme (README)` --references--> `ntfymeApp`  [INFERRED]
  README.md → ntfyme/ntfymeApp.swift
- `ntfyme (README)` --references--> `AVAudioPlayer sandbox-safe sound playback`  [EXTRACTED]
  README.md → ntfyme/NotificationService.swift
- `ntfyme (README)` --references--> `Menu Bar Agent (LSUIElement) pattern`  [EXTRACTED]
  README.md → ntfyme/ntfymeApp.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Message delivery pipeline (stream to notification)** — ntfyme_store_streamloop, ntfyme_store_receive, ntfyme_notificationservice_deliver, ntfyme_models_ntfymessage [EXTRACTED 1.00]
- **Message rendering theme/emoji/priority stack** — ntfyme_theme_theme, ntfyme_emoji_emoji, ntfyme_models_prioritylevel, ntfyme_contentview_messagecard, ntfyme_historyview_historyrow [INFERRED 0.85]
- **Main window tabbed scenes** — ntfyme_settingsview_mainwindowview, ntfyme_settingsview_generalsettingsview, ntfyme_settingsview_subscriptionssettingsview, ntfyme_historyview_historyview, ntfyme_settingsview_aboutsettingsview [EXTRACTED 1.00]

## Communities (20 total, 1 thin omitted)

### Community 0 - "Settings & Main Window UI"
Cohesion: 0.09
Nodes (30): Context, Coordinator, NSClickGestureRecognizer, NSObject, NSView, NSViewRepresentable, AboutSettingsView, AppearancePreviewRow (+22 more)

### Community 1 - "Store & Persistence"
Cohesion: 0.11
Nodes (12): escaping, Never, Store, Bool, Int, NtfyMessage, String, Subscription (+4 more)

### Community 2 - "Message Models"
Cohesion: 0.14
Nodes (25): AttributedString, Codable, Date, Decoder, Hashable, Identifiable, NtfyAttachment, NtfyMessage (+17 more)

### Community 3 - "Menu Bar Popup"
Cohesion: 0.13
Nodes (20): Liquid Glass availability gating, MainWindowTab, Material, ConnectionIndicator, GlassBackground, MenuRow, MessageCard, PopupListHeightKey (+12 more)

### Community 4 - "App Lifecycle & Design Concepts"
Cohesion: 0.11
Nodes (22): App, ntfyme App Store Listing, Automatic Termination opt-out, AVAudioPlayer sandbox-safe sound playback, Menu Bar Agent (LSUIElement) pattern, usernoted icon caching, ntfy pub/sub service, Stream Replay via ?since= parameter (+14 more)

### Community 5 - "Notification Delivery"
Cohesion: 0.15
Nodes (10): AVAudioPlayer, NotificationService, NtfyMessage, String, Void, UNNotification, UNNotificationPresentationOptions, UNNotificationResponse (+2 more)

### Community 6 - "Attachment Rendering"
Cohesion: 0.19
Nodes (12): NtfyAttachment, Attachments, AttachmentView, AuthAsyncImage, AuthAsyncImagePhase, empty, failure, success (+4 more)

### Community 7 - "Emoji & History View"
Cohesion: 0.23
Nodes (9): Emoji, String, HistoryRow, HistoryView, NtfyMessage, Store, String, Subscription (+1 more)

### Community 8 - "Message Coding Keys"
Cohesion: 0.13
Nodes (15): CodingKey, CodingKeys, attachment, click, event, id, message, popupDismissed (+7 more)

### Community 9 - "Theme & Priority Styling"
Cohesion: 0.30
Nodes (6): Color, LocalizedStringKey, NtfyMessage, String, Subscription, Theme

### Community 10 - "Icon Composer Config"
Cohesion: 0.14
Nodes (13): fill, linear-gradient, orientation, groups, start, stop, x, y (+5 more)

### Community 11 - "Connection State Enums"
Cohesion: 0.18
Nodes (10): AggregateConnection, allConnected, allDisconnected, none, partial, ConnectionState, connected, connecting (+2 more)

### Community 12 - "Terminal Glyph Concepts"
Cohesion: 0.38
Nodes (7): App Icon Foreground Layer, Rounded Chat Bubble Outline, Terminal Glyph (Chat Bubble with Prompt), Terminal Prompt Symbol (Chevron and Underscore), Command-Line/Terminal Concept, Notification/Messaging Concept, ntfyme App Identity

### Community 13 - "Bell Icon Concepts"
Cohesion: 0.33
Nodes (7): bell.imageset (Xcode Asset Catalog Image Set), bell.svg (Font Awesome Bell Glyph), Bell Icon Glyph, Font Awesome Pro 5.15.4, Menu Bar Icon, Notification (ntfy), SVG Vector Graphic (viewBox 0 0 448 512)

### Community 14 - "Asset Catalog Metadata A"
Cohesion: 0.29
Nodes (6): images, info, author, version, properties, template-rendering-intent

### Community 15 - "Asset Catalog Metadata B"
Cohesion: 0.29
Nodes (6): images, info, author, version, properties, template-rendering-intent

### Community 16 - "ntfyme Logo Concepts"
Cohesion: 0.40
Nodes (6): ntfyme App Logo, Chevron (Greater-Than) Symbol, Horizontal Bar Element, Notification/Messaging Concept, ntfyme Logo SVG, Speech Bubble Glyph

### Community 17 - "Accent Color Asset"
Cohesion: 0.40
Nodes (4): colors, info, author, version

### Community 18 - "Asset Catalog Root"
Cohesion: 0.50
Nodes (3): info, author, version

## Knowledge Gaps
- **89 isolated node(s):** `linear-gradient`, `x`, `y`, `x`, `y` (+84 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Store` connect `Store & Persistence` to `Settings & Main Window UI`, `Message Models`, `Menu Bar Popup`, `App Lifecycle & Design Concepts`, `Emoji & History View`, `Connection State Enums`?**
  _High betweenness centrality (0.266) - this node is a cross-community bridge._
- **Why does `NtfyMessage` connect `Message Models` to `Store & Persistence`, `Menu Bar Popup`, `Theme & Priority Styling`, `Emoji & History View`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **Why does `StatusBarPopupView` connect `Menu Bar Popup` to `Settings & Main Window UI`, `Store & Persistence`, `Connection State Enums`, `App Lifecycle & Design Concepts`?**
  _High betweenness centrality (0.097) - this node is a cross-community bridge._
- **What connects `linear-gradient`, `x`, `y` to the rest of the system?**
  _90 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Settings & Main Window UI` be split into smaller, more focused modules?**
  _Cohesion score 0.09302325581395349 - nodes in this community are weakly interconnected._
- **Should `Store & Persistence` be split into smaller, more focused modules?**
  _Cohesion score 0.11363636363636363 - nodes in this community are weakly interconnected._
- **Should `Message Models` be split into smaller, more focused modules?**
  _Cohesion score 0.13793103448275862 - nodes in this community are weakly interconnected._