import Foundation

// Subset of the GitHub-style emoji shortcodes ntfy uses for tag-based
// title prefixes. When a message tag matches a key here, the emoji is
// rendered into the title the same way the iOS/Android/web clients do.
// Extend as needed — the canonical list lives in ntfy's web client.
enum Emoji {
    static func split(tags: [String]?) -> (emojis: [String], plain: [String]) {
        guard let tags else { return ([], []) }
        var emojis: [String] = []
        var plain: [String] = []
        for tag in tags {
            if let emoji = map[tag.lowercased()] {
                emojis.append(emoji)
            } else {
                plain.append(tag)
            }
        }
        return (emojis, plain)
    }

    static func prefix(for tags: [String]?) -> String {
        split(tags: tags).emojis.joined(separator: " ")
    }

    static func decorate(_ title: String, tags: [String]?) -> String {
        let p = prefix(for: tags)
        return p.isEmpty ? title : "\(p) \(title)"
    }

    private static let map: [String: String] = [
        // Alerts / status
        "warning": "⚠️", "rotating_light": "🚨", "triangular_flag_on_post": "🚩",
        "fire": "🔥", "bomb": "💣", "skull": "💀", "skull_and_crossbones": "☠️",
        "no_entry": "⛔", "no_entry_sign": "🚫", "stop_sign": "🛑",
        "boom": "💥", "collision": "💥", "exclamation": "❗", "grey_exclamation": "❕",
        "question": "❓", "grey_question": "❔", "interrobang": "⁉️",
        "white_check_mark": "✅", "heavy_check_mark": "✔️", "ballot_box_with_check": "☑️",
        "x": "❌", "negative_squared_cross_mark": "❎",
        "thumbsup": "👍", "+1": "👍", "thumbsdown": "👎", "-1": "👎",
        "ok_hand": "👌", "100": "💯", "muscle": "💪",

        // Weather / nature
        "sunny": "☀️", "partly_sunny": "⛅", "cloud": "☁️",
        "cloud_with_rain": "🌧", "cloud_with_lightning": "🌩",
        "cloud_with_snow": "🌨", "cloud_with_lightning_and_rain": "⛈",
        "snowflake": "❄️", "snowman": "⛄", "umbrella": "☂️",
        "umbrella_with_rain_drops": "☔", "rainbow": "🌈",
        "zap": "⚡", "tornado": "🌪", "fog": "🌫",
        "sun_with_face": "🌞", "moon": "🌙", "crescent_moon": "🌙",
        "earth_americas": "🌎", "earth_africa": "🌍", "earth_asia": "🌏",

        // Tech
        "computer": "💻", "desktop_computer": "🖥", "keyboard": "⌨️",
        "iphone": "📱", "calling": "📲", "battery": "🔋", "electric_plug": "🔌",
        "cd": "💿", "dvd": "📀", "floppy_disk": "💾", "minidisc": "💽",
        "satellite": "🛰", "satellite_antenna": "📡", "tv": "📺", "radio": "📻",
        "watch": "⌚", "alarm_clock": "⏰", "stopwatch": "⏱", "hourglass": "⌛",
        "hourglass_flowing_sand": "⏳", "clock1": "🕐",
        "robot": "🤖", "joystick": "🕹", "video_game": "🎮", "printer": "🖨",
        "mouse_three_button": "🖱", "trackball": "🖲",

        // Locks / keys
        "lock": "🔒", "unlock": "🔓", "lock_with_ink_pen": "🔏",
        "closed_lock_with_key": "🔐", "key": "🔑", "old_key": "🗝",

        // Sound / bell
        "bell": "🔔", "no_bell": "🔕", "loud_sound": "🔊", "speaker": "🔈",
        "sound": "🔉", "mute": "🔇", "mega": "📣", "loudspeaker": "📢",
        "musical_note": "🎵", "notes": "🎶",

        // Mail / messages
        "email": "📧", "e-mail": "📧", "envelope": "✉️",
        "envelope_with_arrow": "📩", "incoming_envelope": "📨",
        "mailbox": "📫", "mailbox_closed": "📪",
        "mailbox_with_mail": "📬", "mailbox_with_no_mail": "📭",
        "love_letter": "💌", "package": "📦", "postbox": "📮",
        "telephone": "☎️", "phone": "☎️", "fax": "📠", "pager": "📟",

        // Celebrations / shiny
        "tada": "🎉", "confetti_ball": "🎊", "balloon": "🎈",
        "gift": "🎁", "trophy": "🏆", "medal": "🏅", "first_place_medal": "🥇",
        "second_place_medal": "🥈", "third_place_medal": "🥉",
        "star": "⭐", "star2": "🌟", "sparkles": "✨", "dizzy": "💫",
        "fireworks": "🎆", "sparkler": "🎇", "heart": "❤️", "broken_heart": "💔",
        "two_hearts": "💕", "heartpulse": "💗",

        // Faces (selective)
        "cry": "😢", "sob": "😭", "rage": "😡", "angry": "😠",
        "scream": "😱", "weary": "😩", "tired_face": "😫",
        "exploding_head": "🤯", "hot_face": "🥵", "cold_face": "🥶",
        "smile": "😄", "grin": "😁", "joy": "😂", "rofl": "🤣",
        "wink": "😉", "thinking": "🤔", "see_no_evil": "🙈",

        // Money / business
        "money_bag": "💰", "moneybag": "💰", "money_with_wings": "💸",
        "dollar": "💵", "euro": "💶", "yen": "💴", "pound": "💷",
        "credit_card": "💳", "receipt": "🧾",
        "chart_with_upwards_trend": "📈", "chart_with_downwards_trend": "📉",
        "bar_chart": "📊",

        // Build / dev / monitoring
        "rocket": "🚀", "construction": "🚧", "construction_worker": "👷",
        "hammer": "🔨", "hammer_and_wrench": "🛠", "wrench": "🔧",
        "nut_and_bolt": "🔩", "gear": "⚙️", "toolbox": "🧰",
        "bug": "🐛", "ant": "🐜", "spider": "🕷", "octopus": "🐙",
        "shield": "🛡", "fire_extinguisher": "🧯",

        // Lab / science / health
        "test_tube": "🧪", "microscope": "🔬", "telescope": "🔭",
        "dna": "🧬", "petri_dish": "🧫", "syringe": "💉",
        "pill": "💊", "stethoscope": "🩺", "thermometer": "🌡",
        "hospital": "🏥", "ambulance": "🚑", "mask": "😷",

        // Buildings / doors
        "house": "🏠", "house_with_garden": "🏡", "office": "🏢",
        "school": "🏫", "factory": "🏭", "post_office": "🏤",
        "bank": "🏦", "hotel": "🏨", "convenience_store": "🏪",
        "door": "🚪", "doorbell": "🛎",

        // Transport
        "car": "🚗", "blue_car": "🚙", "taxi": "🚕", "bus": "🚌",
        "truck": "🚚", "articulated_lorry": "🚛", "fire_engine": "🚒",
        "police_car": "🚓", "ambulance_emoji": "🚑",
        "bike": "🚲", "scooter": "🛴", "motorcycle": "🏍",
        "airplane": "✈️", "small_airplane": "🛩", "ship": "🚢",
        "boat": "⛵", "sailboat": "⛵", "train": "🚆", "train2": "🚆",
        "tram": "🚊", "metro": "🚇", "bullettrain_front": "🚅",

        // Search / docs
        "eyes": "👀", "eye": "👁", "mag": "🔍", "mag_right": "🔎",
        "memo": "📝", "pencil": "✏️", "page_facing_up": "📄",
        "page_with_curl": "📃", "scroll": "📜", "bookmark": "🔖",
        "books": "📚", "book": "📖", "newspaper": "📰",
        "clipboard": "📋", "calendar": "📅", "date": "📅",
        "spiral_calendar_pad": "🗓",

        // People / gestures
        "wave": "👋", "pray": "🙏", "raised_hands": "🙌",
        "clap": "👏", "handshake": "🤝", "point_up": "☝️", "point_down": "👇",
        "point_left": "👈", "point_right": "👉",

        // Misc
        "label": "🏷", "link": "🔗",
        "paperclip": "📎", "scissors": "✂️", "pushpin": "📌",
        "round_pushpin": "📍", "triangular_ruler": "📐", "straight_ruler": "📏",
        "calculator": "🔢"
    ]
}
