import Foundation
import AppKit

struct Subscription: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var topic: String
    var serverURL: String?
    var token: String?
    var displayName: String?
    var iconName: String?
    var colorName: String?

    func effectiveServer(default defaultServer: String) -> String {
        let raw = (serverURL?.isEmpty == false ? serverURL! : defaultServer)
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func streamURL(default defaultServer: String) -> URL? {
        let server = effectiveServer(default: defaultServer)
        let encoded = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? topic
        return URL(string: "\(server)/\(encoded)/json")
    }

    var label: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return topic
    }
}

struct NtfyAttachment: Codable, Hashable, Sendable {
    var name: String
    var url: String
    var type: String?
    var size: Int?
    var expires: Int?

    var fileURL: URL? { URL(string: url) }
    var isImage: Bool { (type ?? "").hasPrefix("image/") }
    var sizeText: String? {
        guard let size, size > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct NtfyMessage: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var time: Int
    var event: String?
    var topic: String
    var message: String?
    var title: String?
    var priority: Int?
    var tags: [String]?
    var click: String?
    var attachment: NtfyAttachment?

    // Local-only, set by store when message arrives.
    var subscriptionID: UUID?
    var read: Bool = false
    var popupDismissed: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, time, event, topic, message, title, priority, tags, click, attachment, subscriptionID, read, popupDismissed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        time = try c.decodeIfPresent(Int.self, forKey: .time) ?? Int(Date().timeIntervalSince1970)
        event = try c.decodeIfPresent(String.self, forKey: .event)
        topic = try c.decodeIfPresent(String.self, forKey: .topic) ?? ""
        message = try c.decodeIfPresent(String.self, forKey: .message)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        priority = try c.decodeIfPresent(Int.self, forKey: .priority)
        tags = try c.decodeIfPresent([String].self, forKey: .tags)
        click = try c.decodeIfPresent(String.self, forKey: .click)
        attachment = try c.decodeIfPresent(NtfyAttachment.self, forKey: .attachment)
        subscriptionID = try c.decodeIfPresent(UUID.self, forKey: .subscriptionID)
        read = try c.decodeIfPresent(Bool.self, forKey: .read) ?? false
        popupDismissed = try c.decodeIfPresent(Bool.self, forKey: .popupDismissed) ?? false
    }

    init(id: String, time: Int, topic: String, message: String?, title: String?,
         priority: Int? = nil, tags: [String]? = nil, click: String? = nil,
         attachment: NtfyAttachment? = nil,
         event: String? = "message", subscriptionID: UUID? = nil,
         read: Bool = false, popupDismissed: Bool = false) {
        self.id = id
        self.time = time
        self.event = event
        self.topic = topic
        self.message = message
        self.title = title
        self.priority = priority
        self.tags = tags
        self.click = click
        self.attachment = attachment
        self.subscriptionID = subscriptionID
        self.read = read
        self.popupDismissed = popupDismissed
    }

    var date: Date { Date(timeIntervalSince1970: TimeInterval(time)) }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return topic
    }

    var displayBody: String { message ?? "" }

    enum PriorityLevel: Int, Sendable {
        case min = 1, low = 2, normal = 3, high = 4, max = 5
    }

    var priorityLevel: PriorityLevel {
        guard let priority else { return .normal }
        return PriorityLevel(rawValue: priority) ?? .normal
    }

    // Body with autodetected URLs marked as `.link` so SwiftUI's
    // Text(AttributedString) renders them tappable.
    var displayBodyAttributed: AttributedString {
        let body = displayBody
        guard !body.isEmpty else { return AttributedString() }
        let mutable = NSMutableAttributedString(string: body)
        let range = NSRange(location: 0, length: (body as NSString).length)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            detector.enumerateMatches(in: body, range: range) { match, _, _ in
                guard let match, let url = match.url else { return }
                mutable.addAttribute(.link, value: url, range: match.range)
            }
        }
        return AttributedString(mutable)
    }
}
