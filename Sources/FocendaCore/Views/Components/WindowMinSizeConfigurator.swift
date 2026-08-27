import SwiftUI
#if os(macOS)
import AppKit

/// Configures and locks the minimum window size on the AppKit `NSWindow` level.
public struct WindowMinSizeConfigurator: NSViewRepresentable {
    public let minWidth: CGFloat
    public let minHeight: CGFloat

    public init(minWidth: CGFloat, minHeight: CGFloat) {
        self.minWidth = minWidth
        self.minHeight = minHeight
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.minSize = NSSize(width: minWidth, height: minHeight)
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.minSize = NSSize(width: minWidth, height: minHeight)
            }
        }
    }
}

public extension View {
    /// Enforces a hard minimum window width and height on macOS at the `NSWindow` level.
    func enforceMinimumWindowSize(width: CGFloat, height: CGFloat) -> some View {
        self.background(WindowMinSizeConfigurator(minWidth: width, minHeight: height))
    }
}
#else
public extension View {
    func enforceMinimumWindowSize(width: CGFloat, height: CGFloat) -> some View {
        self
    }
}
#endif
