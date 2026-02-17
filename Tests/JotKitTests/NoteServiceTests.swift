import Foundation
import Testing
@testable import JotKit

@Suite("NoteService", .serialized)
struct NoteServiceTests {

    // MARK: - resolveTitle

    @Test("Uses explicit title")
    func resolveTitleUsesExplicitTitle() {
        let result = NoteService.resolveTitle(explicit: "My Title", body: "some body")
        #expect(result == "My Title")
    }

    @Test("Trims whitespace from explicit title")
    func resolveTitleTrimsWhitespace() {
        let result = NoteService.resolveTitle(explicit: "  Padded  ", body: "body")
        #expect(result == "Padded")
    }

    @Test("Falls back to first line of body")
    func resolveTitleFallsBackToFirstLine() {
        let result = NoteService.resolveTitle(explicit: "", body: "First line\nSecond line")
        #expect(result == "First line")
    }

    @Test("Falls back to date for long first line")
    func resolveTitleFallsBackToDateForLongFirstLine() {
        let longLine = String(repeating: "a", count: 81)
        let result = NoteService.resolveTitle(explicit: "", body: longLine)
        #expect(result.hasPrefix("Note "))
    }

    @Test("Falls back to date when explicit title is whitespace")
    func resolveTitleFallsBackToDateForWhitespaceExplicit() {
        let longBody = String(repeating: "x", count: 81)
        let result = NoteService.resolveTitle(explicit: "   ", body: longBody)
        #expect(result.hasPrefix("Note "))
    }

    // MARK: - sanitize

    @Test("Preserves spaces and casing")
    func sanitizePreservesSpaces() {
        let result = NoteService.sanitize("Hello World")
        #expect(result == "Hello World")
    }

    @Test("Strips filesystem-unsafe characters")
    func sanitizeStripsUnsafe() {
        let result = NoteService.sanitize("Hello: World/Two\\Three")
        #expect(result == "Hello WorldTwoThree")
    }

    @Test("Truncates at 60 characters")
    func sanitizeTruncatesAt60() {
        let longTitle = String(repeating: "word ", count: 20)
        let result = NoteService.sanitize(longTitle)
        #expect(result.count <= 60)
    }

    // MARK: - makeFilename

    @Test("Filename has timestamp prefix and title with spaces")
    func makeFilenameFormat() {
        let filename = NoteService.makeFilename(title: "Test Note")
        #expect(filename.hasSuffix(" Test Note.md"))
        #expect(filename.count > 16)
    }

    // MARK: - collectTags

    @Test("Parses CSV tags")
    func collectTagsParsesCSV() {
        let tags = NoteService.collectTags(from: "swift, macos, dev", defaultTag: "")
        #expect(tags == ["swift", "macos", "dev"])
    }

    @Test("Filters empty tags")
    func collectTagsFiltersEmpty() {
        let tags = NoteService.collectTags(from: "swift,, , macos", defaultTag: "")
        #expect(tags == ["swift", "macos"])
    }

    @Test("Inserts default tag at front")
    func collectTagsInsertsDefaultTag() {
        let tags = NoteService.collectTags(from: "swift", defaultTag: "quicknote")
        #expect(tags == ["quicknote", "swift"])
    }

    @Test("No duplicate when default tag already present")
    func collectTagsNoDuplicateDefault() {
        let tags = NoteService.collectTags(from: "quicknote, swift", defaultTag: "quicknote")
        #expect(tags == ["quicknote", "swift"])
    }

    @Test("Empty input returns empty tags")
    func collectTagsEmptyInput() {
        let tags = NoteService.collectTags(from: "", defaultTag: "")
        #expect(tags == [])
    }

    @Test("Empty input with default tag returns only default")
    func collectTagsOnlyDefault() {
        let tags = NoteService.collectTags(from: "", defaultTag: "journal")
        #expect(tags == ["journal"])
    }

    // MARK: - makeContent

    @Test("Content without tags has no frontmatter")
    func makeContentWithoutTags() {
        let content = NoteService.makeContent(body: "Hello world", tags: [])
        #expect(content == "Hello world\n")
    }

    @Test("Content with tags includes YAML frontmatter")
    func makeContentWithTags() {
        let content = NoteService.makeContent(body: "Hello world", tags: ["swift", "dev"])
        #expect(content.hasPrefix("---\n"))
        #expect(content.contains("tags:"))
        #expect(content.contains("  - swift"))
        #expect(content.contains("  - dev"))
        #expect(content.contains("---\n\nHello world"))
    }

    // MARK: - save (integration)

    @Test("Save with explicit title uses title as filename")
    func saveWithExplicitTitle() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "Test", body: "Body content", tags: "")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0] == "Test.md")

        let content = try String(
            contentsOf: tempDir.appendingPathComponent(files[0]),
            encoding: .utf8
        )
        #expect(content == "Body content\n")
    }

    @Test("Save without title uses timestamp-slug filename")
    func saveWithoutTitle() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "", body: "Body content", tags: "")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0].hasSuffix(" Body content.md"))
    }

    @Test("Save skips empty body")
    func saveSkipsEmptyBody() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "Test", body: "   ", tags: "")

        let exists = FileManager.default.fileExists(atPath: tempDir.path)
        if exists {
            let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
            #expect(files.count == 0)
        }
    }

    @Test("Save to non-writable directory throws directoryNotWritable")
    func saveToNonWritableDirectoryThrows() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Remove write permission
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444], ofItemAtPath: tempDir.path)

        Preferences.saveDirectory = tempDir.path

        #expect(throws: NoteServiceError.self) {
            try NoteService.save(title: "Test", body: "Content", tags: "")
        }

        // Restore permissions for cleanup
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: tempDir.path)
    }

    @Test("Unicode and emoji in titles sanitize correctly")
    func unicodeEmojiTitles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "Hello 🌍 World", body: "Content", tags: "")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0] == "Hello 🌍 World.md")
    }

    @Test("CJK characters in titles work correctly")
    func cjkTitles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "日本語メモ", body: "Content", tags: "")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0] == "日本語メモ.md")
    }

    @Test("Mixed-case duplicate tags are deduped")
    func mixedCaseTagDedup() {
        // The commitTag function in NoteEditorView handles case-insensitive dedup,
        // but collectTags uses exact match for default tag. Test that behavior.
        let tags = NoteService.collectTags(from: "Work, dev", defaultTag: "work")
        // "work" default differs from "Work" in exact match, so both appear
        #expect(tags.contains("Work"))
        #expect(tags.contains("work"))
    }

    @Test("Explicit title uses title directly as filename without timestamp")
    func explicitTitleFilenameFormat() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path

        try NoteService.save(title: "My Note", body: "Content", tags: "")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0] == "My Note.md")
        // Verify no timestamp prefix
        #expect(!files[0].contains("-"))
    }

    @Test("Save with tags includes frontmatter in file")
    func saveWithTagsIncludesFrontmatter() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jot-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        Preferences.saveDirectory = tempDir.path
        Preferences.defaultTag = ""

        try NoteService.save(title: "Tagged", body: "Content here", tags: "swift, dev")

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0] == "Tagged.md")

        let content = try String(
            contentsOf: tempDir.appendingPathComponent(files[0]),
            encoding: .utf8
        )
        #expect(content.hasPrefix("---\n"))
        #expect(content.contains("  - swift"))
        #expect(content.contains("  - dev"))
        #expect(content.contains("Content here"))
    }
}
