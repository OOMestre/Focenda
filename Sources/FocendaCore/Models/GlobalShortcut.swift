import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Actions triggered by global focus keyboard shortcuts
public enum FocusShortcutAction: String, CaseIterable, Identifiable, Codable {
    case toggleFocus = "toggle_focus"
    case startWork = "start_work"
    case startShortBreak = "start_short_break"
    case startLongBreak = "start_long_break"
    case resetTimer = "reset_timer"
    case skipSession = "skip_session"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .toggleFocus:
            return "Start / Pause Focus"
        case .startWork:
            return "Start Deep Focus"
        case .startShortBreak:
            return "Start Short Break"
        case .startLongBreak:
            return "Start Long Break"
        case .resetTimer:
            return "Reset Timer"
        case .skipSession:
            return "Skip Session"
        }
    }

    public var description: String {
        switch self {
        case .toggleFocus:
            return "Toggles running/pause state of the focus timer"
        case .startWork:
            return "Switches to Deep Focus mode and starts timer"
        case .startShortBreak:
            return "Switches to Short Break mode and starts timer"
        case .startLongBreak:
            return "Switches to Long Break mode and starts timer"
        case .resetTimer:
            return "Resets the current session to initial duration"
        case .skipSession:
            return "Skips to the next Pomodoro cycle mode"
        }
    }

    public var iconName: String {
        switch self {
        case .toggleFocus:
            return "playpause.fill"
        case .startWork:
            return "brain.head.profile"
        case .startShortBreak:
            return "cup.and.saucer.fill"
        case .startLongBreak:
            return "leaf.fill"
        case .resetTimer:
            return "arrow.counterclockwise"
        case .skipSession:
            return "forward.fill"
        }
    }

    public var numericId: UInt32 {
        switch self {
        case .toggleFocus: return 1001
        case .startWork: return 1002
        case .startShortBreak: return 1003
        case .startLongBreak: return 1004
        case .resetTimer: return 1005
        case .skipSession: return 1006
        }
    }

    public static func from(numericId: UInt32) -> FocusShortcutAction? {
        allCases.first(where: { $0.numericId == numericId })
    }
}

/// Modifier keys supported by global shortcuts
public enum ShortcutModifier: String, CaseIterable, Codable, Sendable {
    case command = "command"
    case option = "option"
    case control = "control"
    case shift = "shift"

    public var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }

    public var carbonModifier: UInt32 {
        switch self {
        case .command: return 0x0100 // cmdKey
        case .shift: return 0x0200   // shiftKey
        case .option: return 0x0800  // optionKey
        case .control: return 0x1000 // controlKey
        }
    }

    #if canImport(AppKit)
    public var nsEventFlag: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .option: return .option
        case .control: return .control
        case .shift: return .shift
        }
    }
    #endif
}

/// Global shortcut preset schemes
public enum GlobalShortcutPreset: String, CaseIterable, Identifiable, Codable {
    case standard = "standard"         // ⌥ ⌘ (Option + Command)
    case powerUser = "power_user"     // ⌃ ⌥ ⌘ (Control + Option + Command)
    case controlOption = "ctrl_opt"   // ⌃ ⌥ (Control + Option)

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard:
            return "Standard (⌥ ⌘)"
        case .powerUser:
            return "Power User (⌃ ⌥ ⌘)"
        case .controlOption:
            return "Compact (⌃ ⌥)"
        }
    }

    public var modifiers: [ShortcutModifier] {
        switch self {
        case .standard:
            return [.option, .command]
        case .powerUser:
            return [.control, .option, .command]
        case .controlOption:
            return [.control, .option]
        }
    }
}

/// Represents a configured key combination for a specific focus action
public struct ShortcutKeyCombination: Identifiable, Equatable, Codable {
    public var id: String { action.rawValue }
    public var action: FocusShortcutAction
    public var keyCode: UInt32
    public var keyCharacter: String
    public var modifiers: [ShortcutModifier]

    public init(
        action: FocusShortcutAction,
        keyCode: UInt32,
        keyCharacter: String,
        modifiers: [ShortcutModifier]
    ) {
        self.action = action
        self.keyCode = keyCode
        self.keyCharacter = keyCharacter.uppercased()
        self.modifiers = modifiers
    }

    /// Carbon modifier mask sum
    public var carbonModifiers: UInt32 {
        modifiers.reduce(0) { $0 | $1.carbonModifier }
    }

    /// Badges to display in macOS keycap UI (e.g. ["⌥", "⌘", "F"])
    public var keyBadges: [String] {
        var badges = modifiers.map { $0.symbol }
        badges.append(keyCharacter)
        return badges
    }

    /// Display string e.g. "⌥ ⌘ F"
    public var displayString: String {
        keyBadges.joined(separator: " ")
    }

    #if canImport(AppKit)
    public var eventModifierFlags: NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        for mod in modifiers {
            flags.insert(mod.nsEventFlag)
        }
        return flags
    }
    #endif

    /// Default shortcut combinations for a given preset
    public static func defaultCombinations(for preset: GlobalShortcutPreset) -> [ShortcutKeyCombination] {
        let mods = preset.modifiers
        return [
            ShortcutKeyCombination(
                action: .toggleFocus,
                keyCode: CarbonKeyCode.f,
                keyCharacter: "F",
                modifiers: mods
            ),
            ShortcutKeyCombination(
                action: .startWork,
                keyCode: CarbonKeyCode.one,
                keyCharacter: "1",
                modifiers: mods
            ),
            ShortcutKeyCombination(
                action: .startShortBreak,
                keyCode: CarbonKeyCode.two,
                keyCharacter: "2",
                modifiers: mods
            ),
            ShortcutKeyCombination(
                action: .startLongBreak,
                keyCode: CarbonKeyCode.three,
                keyCharacter: "3",
                modifiers: mods
            ),
            ShortcutKeyCombination(
                action: .resetTimer,
                keyCode: CarbonKeyCode.r,
                keyCharacter: "R",
                modifiers: mods
            ),
            ShortcutKeyCombination(
                action: .skipSession,
                keyCode: CarbonKeyCode.s,
                keyCharacter: "S",
                modifiers: mods
            )
        ]
    }
}

/// Standard Virtual Key Codes in macOS Carbon HIToolbox
public enum CarbonKeyCode {
    public static let a: UInt32 = 0x00
    public static let s: UInt32 = 0x01
    public static let d: UInt32 = 0x02
    public static let f: UInt32 = 0x03
    public static let h: UInt32 = 0x04
    public static let g: UInt32 = 0x05
    public static let z: UInt32 = 0x06
    public static let x: UInt32 = 0x07
    public static let c: UInt32 = 0x08
    public static let v: UInt32 = 0x09
    public static let b: UInt32 = 0x0B
    public static let q: UInt32 = 0x0C
    public static let w: UInt32 = 0x0D
    public static let e: UInt32 = 0x0E
    public static let r: UInt32 = 0x0F
    public static let y: UInt32 = 0x10
    public static let t: UInt32 = 0x11
    public static let one: UInt32 = 0x12
    public static let two: UInt32 = 0x13
    public static let three: UInt32 = 0x14
    public static let four: UInt32 = 0x15
    public static let six: UInt32 = 0x16
    public static let five: UInt32 = 0x17
    public static let nine: UInt32 = 0x19
    public static let seven: UInt32 = 0x1A
    public static let eight: UInt32 = 0x1C
    public static let zero: UInt32 = 0x1D
    public static let l: UInt32 = 0x25
    public static let p: UInt32 = 0x23
    public static let space: UInt32 = 0x31
}
