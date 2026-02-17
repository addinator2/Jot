import AppKit
import SwiftUI

struct HighlightedTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.documentView = textView

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        // Set initial text and apply highlighting
        textView.string = text
        if let textStorage = textView.textStorage {
            MarkdownHighlighter.applyHighlighting(to: textStorage)
        }

        // Auto-focus
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Only update if the change came from outside (not from user typing)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            if let textStorage = textView.textStorage {
                MarkdownHighlighter.applyHighlighting(to: textStorage)
            }
            textView.selectedRanges = selectedRanges
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedTextEditor
        weak var textView: NSTextView?
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: HighlightedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string

            // Debounce highlighting to avoid re-computing on every keystroke
            highlightWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak textView] in
                guard let textView, let textStorage = textView.textStorage else { return }
                let selectedRanges = textView.selectedRanges
                textView.undoManager?.disableUndoRegistration()
                MarkdownHighlighter.applyHighlighting(to: textStorage)
                textView.undoManager?.enableUndoRegistration()
                textView.selectedRanges = selectedRanges
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        }
    }
}
