import SwiftUI
#if os(macOS)
import AppKit

/// Configures and locks the minimum window size on the AppKit `NSWindow` level.
public struct WindowMinSizeConfigurator: NSViewRepresentable {
    public let minWidth: CGFloat
    public let minHeight: CGFloat
    public let initialWidth: CGFloat?
    public let initialHeight: CGFloat?
    public let initialSizePreferenceKey: String?

    public init(
        minWidth: CGFloat,
        minHeight: CGFloat,
        initialWidth: CGFloat? = nil,
        initialHeight: CGFloat? = nil,
        initialSizePreferenceKey: String? = nil
    ) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.initialWidth = initialWidth
        self.initialHeight = initialHeight
        self.initialSizePreferenceKey = initialSizePreferenceKey
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                configure(window)
            }
        }
    }

    private func configure(_ window: NSWindow) {
        window.minSize = NSSize(width: minWidth, height: minHeight)

        guard
            let initialWidth,
            let initialHeight,
            let initialSizePreferenceKey,
            !UserDefaults.standard.bool(forKey: initialSizePreferenceKey)
        else {
            return
        }

        let preferredSize = fittedInitialContentSize(
            width: initialWidth,
            height: initialHeight,
            for: window
        )
        window.setContentSize(preferredSize)
        window.center()
        UserDefaults.standard.set(true, forKey: initialSizePreferenceKey)
    }

    private func fittedInitialContentSize(width: CGFloat, height: CGFloat, for window: NSWindow) -> NSSize {
        guard let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame else {
            return NSSize(width: width, height: height)
        }

        let horizontalMargin: CGFloat = 80
        let verticalMargin: CGFloat = 80
        return NSSize(
            width: min(width, max(minWidth, visibleFrame.width - horizontalMargin)),
            height: min(height, max(minHeight, visibleFrame.height - verticalMargin))
        )
    }
}

public extension View {
    /// Enforces a hard minimum window width and height on macOS at the `NSWindow` level.
    func enforceMinimumWindowSize(
        width: CGFloat,
        height: CGFloat,
        initialWidth: CGFloat? = nil,
        initialHeight: CGFloat? = nil,
        initialSizePreferenceKey: String? = nil
    ) -> some View {
        self.background(
            WindowMinSizeConfigurator(
                minWidth: width,
                minHeight: height,
                initialWidth: initialWidth,
                initialHeight: initialHeight,
                initialSizePreferenceKey: initialSizePreferenceKey
            )
        )
    }
}
#else
public extension View {
    func enforceMinimumWindowSize(
        width: CGFloat,
        height: CGFloat,
        initialWidth: CGFloat? = nil,
        initialHeight: CGFloat? = nil,
        initialSizePreferenceKey: String? = nil
    ) -> some View {
        self
    }
}
#endif
