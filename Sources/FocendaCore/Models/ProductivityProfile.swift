import Foundation

/// A simple anchor for a profile window on its selected display.
///
/// The nine choices cover the three horizontal zones (left, center, right)
/// and the three vertical zones (top, middle, bottom) without exposing screen
/// coordinates to users.
public enum ProductivityWindowPosition: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case topLeft
    case topCenter
    case topRight
    case middleLeft
    case center
    case middleRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .center: return "Center"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }

    public var systemImage: String {
        switch self {
        case .topLeft: return "arrow.up.left"
        case .topCenter: return "arrow.up"
        case .topRight: return "arrow.up.right"
        case .middleLeft: return "arrow.left"
        case .center: return "circle"
        case .middleRight: return "arrow.right"
        case .bottomLeft: return "arrow.down.left"
        case .bottomCenter: return "arrow.down"
        case .bottomRight: return "arrow.down.right"
        }
    }

    /// Returns the closest semantic anchor to a window frame.
    public static func nearest(
        to frame: CGRect,
        in visibleFrame: CGRect,
        edgePadding: CGFloat = 24
    ) -> Self {
        allCases.min { left, right in
            distanceSquared(
                from: frame.origin,
                to: left.origin(in: visibleFrame, windowSize: frame.size, edgePadding: edgePadding)
            ) < distanceSquared(
                from: frame.origin,
                to: right.origin(in: visibleFrame, windowSize: frame.size, edgePadding: edgePadding)
            )
        } ?? .center
    }

    /// Returns the origin for this anchor while keeping the window on screen.
    public func origin(
        in visibleFrame: CGRect,
        windowSize: CGSize,
        edgePadding: CGFloat = 24
    ) -> CGPoint {
        let width = max(0, windowSize.width)
        let height = max(0, windowSize.height)
        let padding = max(0, edgePadding)

        let minimumX = visibleFrame.minX
        let maximumX = max(minimumX, visibleFrame.maxX - width)
        let minimumY = visibleFrame.minY
        let maximumY = max(minimumY, visibleFrame.maxY - height)

        let leftX = clamped(visibleFrame.minX + padding, minimum: minimumX, maximum: maximumX)
        let centerX = clamped(visibleFrame.midX - width / 2, minimum: minimumX, maximum: maximumX)
        let rightX = clamped(visibleFrame.maxX - padding - width, minimum: minimumX, maximum: maximumX)
        let bottomY = clamped(visibleFrame.minY + padding, minimum: minimumY, maximum: maximumY)
        let middleY = clamped(visibleFrame.midY - height / 2, minimum: minimumY, maximum: maximumY)
        let topY = clamped(visibleFrame.maxY - padding - height, minimum: minimumY, maximum: maximumY)

        switch self {
        case .topLeft: return CGPoint(x: leftX, y: topY)
        case .topCenter: return CGPoint(x: centerX, y: topY)
        case .topRight: return CGPoint(x: rightX, y: topY)
        case .middleLeft: return CGPoint(x: leftX, y: middleY)
        case .center: return CGPoint(x: centerX, y: middleY)
        case .middleRight: return CGPoint(x: rightX, y: middleY)
        case .bottomLeft: return CGPoint(x: leftX, y: bottomY)
        case .bottomCenter: return CGPoint(x: centerX, y: bottomY)
        case .bottomRight: return CGPoint(x: rightX, y: bottomY)
        }
    }

    private static func distanceSquared(from origin: CGPoint, to other: CGPoint) -> CGFloat {
        let deltaX = origin.x - other.x
        let deltaY = origin.y - other.y
        return deltaX * deltaX + deltaY * deltaY
    }

    private func clamped(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

/// A window layout stored relative to a display's visible frame.
///
/// Keeping coordinates relative to the selected display means a profile remains
/// useful when the display arrangement changes or a different monitor becomes
/// the primary display. New layouts use `position`; `x` and `y` are retained
/// to read and apply profiles created by older versions of Focenda.
public struct ProductivityWindowLayout: Codable, Equatable, Sendable {
    public static let minimumWidth: Double = 320
    public static let minimumHeight: Double = 220

    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var screenID: UInt32?
    public var screenName: String
    /// A semantic position on the selected display. `nil` identifies a legacy
    /// coordinate-based layout and preserves its original placement.
    public var position: ProductivityWindowPosition?

    public init(
        x: Double = 60,
        y: Double = 60,
        width: Double = 900,
        height: Double = 700,
        screenID: UInt32? = nil,
        screenName: String = "",
        position: ProductivityWindowPosition? = nil
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.screenID = screenID
        self.screenName = screenName
        self.position = position
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
        case width
        case height
        case screenID
        case screenName
        case position
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 60
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 60
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 900
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 700
        screenID = try container.decodeIfPresent(UInt32.self, forKey: .screenID)
        screenName = try container.decodeIfPresent(String.self, forKey: .screenName) ?? ""

        // Older profile data has no position key. Keeping it nil allows the
        // window manager to continue applying the saved x/y coordinates.
        position = try? container.decode(ProductivityWindowPosition.self, forKey: .position)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encodeIfPresent(screenID, forKey: .screenID)
        try container.encode(screenName, forKey: .screenName)
        try container.encodeIfPresent(position, forKey: .position)
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
        windowLayout: ProductivityWindowLayout = ProductivityWindowLayout(position: .center),
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
