import SwiftUI
import AppKit

/// Introspects the enclosing NSScrollView and forces visible horizontal and/or vertical scrollers for mouse navigation
public struct ForceVisibleScrollerModifier: ViewModifier {
    public let horizontal: Bool
    public let vertical: Bool

    public init(horizontal: Bool = true, vertical: Bool = true) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ScrollViewIntrospectorView(horizontal: horizontal, vertical: vertical)
            )
    }
}

private struct ScrollViewIntrospectorView: NSViewRepresentable {
    let horizontal: Bool
    let vertical: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = findEnclosingScrollView(from: view) {
                if horizontal {
                    scrollView.hasHorizontalScroller = true
                    scrollView.horizontalScroller?.isHidden = false
                }
                if vertical {
                    scrollView.hasVerticalScroller = true
                    scrollView.verticalScroller?.isHidden = false
                }
                scrollView.autohidesScrollers = false
                scrollView.scrollerStyle = .legacy
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = findEnclosingScrollView(from: nsView) {
                if horizontal {
                    scrollView.hasHorizontalScroller = true
                    scrollView.horizontalScroller?.isHidden = false
                }
                if vertical {
                    scrollView.hasVerticalScroller = true
                    scrollView.verticalScroller?.isHidden = false
                }
                scrollView.autohidesScrollers = false
                scrollView.scrollerStyle = .legacy
            }
        }
    }

    private func findEnclosingScrollView(from view: NSView) -> NSScrollView? {
        var current: NSView? = view
        while let parent = current?.superview {
            if let scrollView = parent as? NSScrollView {
                return scrollView
            }
            current = parent
        }
        return nil
    }
}

public extension View {
    /// Forces the enclosing NSScrollView to always display scrollbars for mouse users
    func forceVisibleScrollers(horizontal: Bool = true, vertical: Bool = true) -> some View {
        self.modifier(ForceVisibleScrollerModifier(horizontal: horizontal, vertical: vertical))
    }
}
