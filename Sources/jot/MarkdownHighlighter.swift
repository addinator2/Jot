import AppKit

enum MarkdownHighlighter {
    // Pre-compiled regex patterns
    private static let headingRegex = try! NSRegularExpression(pattern: #"^(#{1,6})\s+.*$"#, options: .anchorsMatchLines)
    private static let boldStarRegex = try! NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#)
    private static let boldUnderRegex = try! NSRegularExpression(pattern: #"__(.+?)__"#)
    private static let italicStarRegex = try! NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#)
    private static let italicUnderRegex = try! NSRegularExpression(pattern: #"(?<!_)_(?!_)(.+?)(?<!_)_(?!_)"#)
    private static let linkRegex = try! NSRegularExpression(pattern: #"\[.+?\]\(.+?\)"#)
    private static let listRegex = try! NSRegularExpression(pattern: #"^(\s*)([-*+]|\d+\.)\s"#, options: .anchorsMatchLines)
    private static let blockquoteRegex = try! NSRegularExpression(pattern: #"^>\s?.*$"#, options: .anchorsMatchLines)
    private static let inlineCodeRegex = try! NSRegularExpression(pattern: #"`[^`]+`"#)

    static func applyHighlighting(to textStorage: NSTextStorage) {
        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        // Reset to base style
        let baseFont = NSFont.systemFont(ofSize: 14)
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
        ], range: fullRange)

        // Headings: ^#{1,6}\s+.*$
        applyRegex(headingRegex, to: textStorage, fullRange: fullRange, text: text) { match in
            let hashRange = match.range(at: 1)
            let level = (text as NSString).substring(with: hashRange).count
            let size: CGFloat = max(14, 22 - CGFloat(level) * 2)
            return [
                .font: NSFont.boldSystemFont(ofSize: size),
                .foregroundColor: NSColor.systemOrange,
            ]
        }

        // Bold: **...**  or __...__
        applyRegex(boldStarRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.font: NSFont.boldSystemFont(ofSize: 14)]
        }
        applyRegex(boldUnderRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.font: NSFont.boldSystemFont(ofSize: 14)]
        }

        // Italic: *...* or _..._
        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
        applyRegex(italicStarRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.font: italicFont]
        }
        applyRegex(italicUnderRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.font: italicFont]
        }

        // Links: [text](url)
        applyRegex(linkRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.foregroundColor: NSColor.systemBlue]
        }

        // Lists: bullets and numbered
        applyRegex(listRegex, to: textStorage, fullRange: fullRange, text: text) { match in
            return (match.range(at: 2), [.foregroundColor: NSColor.systemOrange])
        }

        // Blockquotes: ^>...
        applyRegex(blockquoteRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [.foregroundColor: NSColor.secondaryLabelColor]
        }

        // Inline code: `...` (applied last to override bold/italic within code)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        applyRegex(inlineCodeRegex, to: textStorage, fullRange: fullRange, text: text) { _ in
            [
                .font: monoFont,
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.quaternaryLabelColor,
            ]
        }
    }

    // Overload that applies attrs to the full match
    private static func applyRegex(
        _ regex: NSRegularExpression,
        to textStorage: NSTextStorage,
        fullRange: NSRange,
        text: String,
        attrs: (NSTextCheckingResult) -> [NSAttributedString.Key: Any]
    ) {
        for match in regex.matches(in: text, range: fullRange) {
            textStorage.addAttributes(attrs(match), range: match.range)
        }
    }

    // Overload that returns (subrange, attrs)
    private static func applyRegex(
        _ regex: NSRegularExpression,
        to textStorage: NSTextStorage,
        fullRange: NSRange,
        text: String,
        attrs: (NSTextCheckingResult) -> (NSRange, [NSAttributedString.Key: Any])
    ) {
        for match in regex.matches(in: text, range: fullRange) {
            let (range, attributes) = attrs(match)
            textStorage.addAttributes(attributes, range: range)
        }
    }
}
