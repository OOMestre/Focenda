import SwiftUI
import AppKit

/// Finds the complete line represented by the current NSTextView selection.
///
/// A zero-length selection is treated as the line containing the insertion
/// point, which keeps the action useful without requiring pixel-perfect text
/// selection before every task capture.
enum ScratchpadTextSelection {
    static func lineText(in text: String, selectedRange: NSRange) -> String? {
        let nsText = text as NSString
        guard nsText.length > 0,
              selectedRange.location != NSNotFound,
              selectedRange.location >= 0,
              selectedRange.location <= nsText.length else {
            return nil
        }

        let availableLength = nsText.length - selectedRange.location
        let clampedLength = min(max(selectedRange.length, 0), availableLength)
        let normalizedRange = NSRange(
            location: selectedRange.location,
            length: clampedLength
        )

        // A caret after a trailing newline is on a new, empty line. Do not
        // accidentally turn the previous line into a task in that case.
        if normalizedRange.length == 0,
           normalizedRange.location == nsText.length,
           text.hasSuffix("\n") || text.hasSuffix("\r") {
            return nil
        }

        let lineProbeLocation: Int
        if normalizedRange.length == 0 {
            lineProbeLocation = min(normalizedRange.location, nsText.length - 1)
        } else {
            lineProbeLocation = normalizedRange.location
        }

        let lineRange = nsText.lineRange(
            for: NSRange(location: lineProbeLocation, length: normalizedRange.length)
        )
        let lineText = nsText.substring(with: lineRange)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return lineText.isEmpty ? nil : lineText
    }
}

/// Native NSTextView-backed editor that exposes the line under the cursor or
/// selection while retaining the Scratchpad's existing SwiftUI bindings.
struct ScratchpadTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedLine: String?
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textColor = NSColor(AppTheme.textPrimary)
        textView.insertionPointColor = NSColor(AppTheme.textPrimary)
        textView.font = NSFont.systemFont(ofSize: 15)
        textView.textContainerInset = NSSize(width: 16, height: 14)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text
        textView.setAccessibilityRole(.textArea)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor(AppTheme.textPrimary),
            .paragraphStyle: paragraphStyle
        ]

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? NSTextView else { return }

        textView.textColor = NSColor(AppTheme.textPrimary)
        textView.insertionPointColor = NSColor(AppTheme.textPrimary)

        if textView.string != text {
            textView.string = text
            textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
            selectedLine = nil
        }

        if isFocused {
            guard textView.window?.firstResponder !== textView else { return }
            DispatchQueue.main.async {
                guard self.isFocused, textView.window != nil else { return }
                textView.window?.makeFirstResponder(textView)
            }
        } else if textView.window?.firstResponder === textView {
            textView.window?.makeFirstResponder(nil)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScratchpadTextEditor

        init(parent: ScratchpadTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if parent.text != textView.string {
                parent.text = textView.string
            }
            updateSelectedLine(from: textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateSelectedLine(from: textView)
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.isFocused = true
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.isFocused = false
        }

        func updateSelectedLine(from textView: NSTextView) {
            parent.selectedLine = ScratchpadTextSelection.lineText(
                in: textView.string,
                selectedRange: textView.selectedRange()
            )
        }
    }
}
