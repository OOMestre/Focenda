import Foundation

/// A window layout stored relative to a display's visible frame.
///
/// Keeping coordinates relative to the selected display means a profile remains
/// useful when the display arrangement changes or a different monitor becomes
/// the primary display.
public struct ProductivityWindowLayout: Codable, Equatable, Sendable {
    public static let minimumWidth: Double = 320
    public static let minimumHeight: Double = 220

    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var screenID: UInt32?
    public var screenName: String

    public init(
        x: Double = 60,
        y: Double = 60,
        width: Double = 900,
        height: Double = 700,
        screenID: UInt32? = nil,
        screenName: String = ""
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.screenID = screenID
        self.screenName = screenName
    }

    /// Returns a safe layout for applying to a real display.
    public var sanitized: ProductivityWindowLayout {
        var copy = self
        copy.width = max(Self.minimumWidth, width)
        copy.height = max(Self.minimumHeight, height)
        copy.screenName = screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }

    public var monitorDescription: String {
        let trimmedName = screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Current display" : trimmedName
    }
}

/// One application/window entry inside a productivity profile.
public struct ProductivityProfileApplication: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var bundleIdentifier: String
    public var name: String
    public var applicationPath: String
    /// Security-scoped access for app bundles selected through an open panel.
    public var applicationBookmarkData: Data?
    public var windowLayout: ProductivityWindowLayout

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        name: String,
        applicationPath: String,
        windowLayout: ProductivityWindowLayout = ProductivityWindowLayout(),
        applicationBookmarkData: Data? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.applicationPath = applicationPath
        self.applicationBookmarkData = applicationBookmarkData
        self.windowLayout = windowLayout
    }
}

/// A global shortcut that activates one productivity profile.
public struct ProductivityProfileShortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var keyCharacter: String
    public var modifiers: [ShortcutModifier]

    public init(
        keyCode: UInt32,
        keyCharacter: String,
        modifiers: [ShortcutModifier]
    ) {
        self.keyCode = keyCode
        let normalizedCharacter = keyCharacter == " " ? "SPACE" : keyCharacter
        self.keyCharacter = normalizedCharacter.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.modifiers = modifiers
    }

    public var isUsable: Bool {
        !keyCharacter.isEmpty && !modifiers.isEmpty
    }

    public var carbonModifiers: UInt32 {
        modifiers.reduce(0) { $0 | $1.carbonModifier }
    }

    public var keyBadges: [String] {
        modifiers.map(\.symbol) + [keyCharacter]
    }

    public var displayString: String {
        keyBadges.joined(separator: " ")
    }
}

/// A named collection of applications and their saved window layouts.
public struct ProductivityProfile: Codable, Equatable, Identifiable, Sendable {
    public static let defaultName = "New Profile"

    public let id: UUID
    public var name: String
    public var applications: [ProductivityProfileApplication]
    public var globalShortcut: ProductivityProfileShortcut?

    public init(
        id: UUID = UUID(),
        name: String = ProductivityProfile.defaultName,
        applications: [ProductivityProfileApplication] = [],
        globalShortcut: ProductivityProfileShortcut? = nil
    ) {
        self.id = id
        self.name = name
        self.applications = applications
        self.globalShortcut = globalShortcut
    }

    public var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? Self.defaultName : trimmedName
    }
}

/// A display exposed to the profile editor.
public struct ProductivityScreenDescriptor: Equatable, Identifiable, Sendable {
    public let id: UInt32
    public let name: String

    public init(id: UInt32, name: String) {
        self.id = id
        self.name = name
    }
}

#if canImport(AppKit)
import AppKit

public extension ShortcutModifier {
    /// Converts the modifier flags relevant to a profile shortcut into the
    /// same order used by the shortcut badges throughout the app.
    static func from(eventModifiers flags: NSEvent.ModifierFlags) -> [ShortcutModifier] {
        var result: [ShortcutModifier] = []
        if flags.contains(.control) { result.append(.control) }
        if flags.contains(.option) { result.append(.option) }
        if flags.contains(.command) { result.append(.command) }
        if flags.contains(.shift) { result.append(.shift) }
        return result
    }
}

public extension ProductivityProfileShortcut {
    init?(event: NSEvent) {
        let modifiers = ShortcutModifier.from(eventModifiers: event.modifierFlags)
        guard !modifiers.isEmpty else { return nil }

        let characters = event.charactersIgnoringModifiers ?? ""
        guard !characters.isEmpty else { return nil }

        self.init(
            keyCode: UInt32(event.keyCode),
            keyCharacter: characters,
            modifiers: modifiers
        )
    }
}
#endif
