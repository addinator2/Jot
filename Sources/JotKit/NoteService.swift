import Foundation

public enum NoteServiceError: LocalizedError {
    case directoryNotWritable(path: String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotWritable(let path):
            return "The save directory is not writable: \(path)"
        }
    }
}

public enum NoteService {
    public static func save(title: String, body: String, tags: String) throws {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }

        let explicitTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = resolveTitle(explicit: title, body: trimmedBody)
        let filename = explicitTitle.isEmpty
            ? makeFilename(title: resolvedTitle)
            : "\(explicitTitle).md"
        let allTags = collectTags(from: tags)
        let content = makeContent(body: trimmedBody, tags: allTags)

        let directory = Preferences.saveDirectory

        try FileManager.default.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )

        guard FileManager.default.isWritableFile(atPath: directory) else {
            throw NoteServiceError.directoryNotWritable(path: directory)
        }

        let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Title Resolution

    static func resolveTitle(explicit: String, body: String) -> String {
        let trimmed = explicit.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        // Use first line of body if short enough
        let firstLine = body.components(separatedBy: .newlines).first ?? ""
        if !firstLine.isEmpty && firstLine.count <= 80 {
            return firstLine
        }

        // Fallback: "Note <date time>"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "Note \(formatter.string(from: Date()))"
    }

    // MARK: - Filename

    static func makeFilename(title: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())

        let sanitized = sanitize(title)

        return "\(timestamp) \(sanitized).md"
    }

    static func sanitize(_ title: String) -> String {
        let illegal = CharacterSet(charactersIn: ":/\\")
        return String(
            title
                .components(separatedBy: illegal)
                .joined()
                .prefix(60)
        )
    }

    // MARK: - Tags

    static func collectTags(from input: String, defaultTag: String? = nil) -> [String] {
        var tags = input
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let resolvedDefault = (defaultTag ?? Preferences.defaultTag)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !resolvedDefault.isEmpty && !tags.contains(resolvedDefault) {
            tags.insert(resolvedDefault, at: 0)
        }

        return tags
    }

    // MARK: - Content

    static func makeContent(body: String, tags: [String]) -> String {
        if tags.isEmpty {
            return body + "\n"
        }

        let tagLines = tags.map { "  - \($0)" }.joined(separator: "\n")
        return """
        ---
        tags:
        \(tagLines)
        ---

        \(body)
        """
    }
}
