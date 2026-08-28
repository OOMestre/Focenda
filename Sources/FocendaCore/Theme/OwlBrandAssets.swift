import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Centralized brand assets and helper utilities for the Focenda Owl identity.
public enum OwlBrandAssets {
    /// Base64 encoded 2x PNG of the Menu Bar Owl Face Template icon (18x18pt / 36x36px @2x)
    private static let menuBarIconBase64 = "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAAXNSR0IArs4c6QAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAJKADAAQAAAABAAAAJAAAAAAJxsHGAAABdUlEQVRYCe1UO04DMRA1UShyhEgUCAnEKdKlASouEMQVgsQhaCiSIl0kxIkQgjoniJQyBYyJBz2Px971rjZJYUvW/N57M5q11phyygbKBsoGgg2cB5nmiYvmVGO+ifwDdwJib5BHDPpLwD8I/AfUPPfEi/zAind51N69Ljs20S4DVW0ttaFNFblFfR3jqg/LgQ/yqGMDdT0MLyjon/pkTNqr1Qa62+MEN3V64d9W+sy/JUfWZMzYswR2y6CUlcIcPzrSgmyf7gtdrkm7pJo97ztj7slKDMcOEjcMlFYyBokmdmB5pB7HHk57Qx4AghH41n0SMYayNsZirs+Taxa1uD6F5DP5nIf0f45raBFngv+AE/RAFYHUsM1yjsfXPtl1jhphcQD068hcSZA3HRRzhVfEPaU7BI06btA/SIBK7lBAreWqvdUkyHU1VLSv9oZgnr9HP8dES39G/OgwTbQvifRK94uu3V7qfjqs5ZRTNlA2cDQb+AXV3X2TTVtt0AAAAABJRU5ErkJggg=="

    /// Native macOS Menu Bar template icon of the Owl Head
    public static var menuBarIcon: NSImage {
        if let data = Data(base64Encoded: menuBarIconBase64),
           let image = NSImage(data: data) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            return image
        }
        return NSImage(systemSymbolName: "timer", accessibilityDescription: "Focenda") ?? NSImage()
    }

    /// Full mascot image (Full Body Owl) for app branding and Dock icon
    public static var mascotImage: NSImage {
        // Check main bundle, bundle resources, or assets directory
        let searchPaths = [
            Bundle.main.path(forResource: "focenda-mascot", ofType: "png"),
            Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
            Bundle.main.resourcePath.map { "\($0)/focenda-mascot.png" },
            "Resources/focenda-mascot.png",
            "assets/focenda-mascot.png"
        ].compactMap { $0 }

        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                return image
            }
        }

        // Fallback to AppIcon image or default system icon
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            return appIcon
        }

        return menuBarIcon
    }

    /// Head icon image (Owl Face)
    public static var headIconImage: NSImage {
        let searchPaths = [
            Bundle.main.path(forResource: "focenda-icon", ofType: "png"),
            Bundle.main.resourcePath.map { "\($0)/focenda-icon.png" },
            "Resources/focenda-icon.png",
            "assets/focenda-icon.png"
        ].compactMap { $0 }

        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                return image
            }
        }

        return menuBarIcon
    }

    /// Configures the macOS Dock icon to display the full body mascot
    public static func configureDockIcon() {
        #if os(macOS)
        let icon = mascotImage
        if icon.isValid {
            NSApplication.shared.applicationIconImage = icon
        }
        #endif
    }
}

/// SwiftUI View representation of the Owl Menu Bar Icon
public struct OwlMenuBarIconView: View {
    public init() {}

    public var body: some View {
        Image(nsImage: OwlBrandAssets.menuBarIcon)
            .renderingMode(.template)
    }
}

/// SwiftUI View displaying the Owl Face logo
public struct OwlFaceView: View {
    public var size: CGFloat

    public init(size: CGFloat = 24) {
        self.size = size
    }

    public var body: some View {
        Image(nsImage: OwlBrandAssets.headIconImage)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

/// SwiftUI View displaying the Full Body Owl Mascot
public struct OwlMascotView: View {
    public var size: CGFloat

    public init(size: CGFloat = 64) {
        self.size = size
    }

    public var body: some View {
        Image(nsImage: OwlBrandAssets.mascotImage)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
