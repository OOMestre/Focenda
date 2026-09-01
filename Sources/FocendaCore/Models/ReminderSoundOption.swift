import Foundation

/// Represents the sound options available for reminder notifications in Focenda
public enum ReminderSoundType: String, CaseIterable, Identifiable, Codable {
    case hero = "Hero"
    case ping = "Ping"
    case glass = "Glass"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case morse = "Morse"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case tink = "Tink"
    case basso = "Basso"
    case custom = "Custom"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .custom:
            return "Custom Audio File..."
        case .hero:
            return "Hero (Default)"
        default:
            return rawValue
        }
    }

    public var isCustom: Bool {
        self == .custom
    }

    public var systemSoundName: String? {
        if self == .custom {
            return nil
        }
        return rawValue
    }

    public static let defaultSound: ReminderSoundType = .hero
    public static let defaultRepeatCount: Int = 3
    public static let minRepeatCount: Int = 1
    public static let maxRepeatCount: Int = 5
}
