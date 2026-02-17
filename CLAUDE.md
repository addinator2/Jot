# CLAUDE.md

## Project overview

jot is a macOS menu bar app for quick note capture. It runs as a background accessory app (no Dock icon), presents a floating panel for writing notes, and saves them as Markdown files with optional YAML frontmatter tags.

## Build & run

```bash
swift build              # debug build
swift build -c release   # release build
swift test               # run tests
./scripts/bundle.sh      # build + bundle as .app
```

Uses [HotKey](https://github.com/soffes/HotKey) for global shortcut registration. Otherwise uses only AppKit, SwiftUI, and Foundation.

## Architecture

The project is split into a library target (`JotKit`) for testable business logic and an executable target (`jot`) for the UI/app layer.

### `Sources/JotKit/` — library target

- **NoteService.swift** — Handles note persistence. Resolves title (explicit → first line → date fallback), generates timestamped slug filenames, builds YAML frontmatter when tags are present, writes to disk. `save()` throws on failure.
- **Preferences.swift** — Thin wrapper around `UserDefaults` for `saveDirectory` and `defaultTag`.

### `Sources/jot/` — executable target (depends on JotKit)

- **main.swift** — Entry point. Sets activation policy to `.accessory` (hides from Dock), creates `AppDelegate`, starts the run loop.
- **AppDelegate.swift** — Sets up the menu bar status item, registers the global Cmd+Shift+N shortcut, and manages the floating panel and settings window lifecycles.
- **FloatingPanel.swift** — `NSPanel` subclass with borderless style, frosted glass (`NSVisualEffectView`), rounded corners. Hosts a SwiftUI view.
- **NoteEditorView.swift** — SwiftUI view with title, tag chips (flow layout), body text editor, and save/cancel buttons. Includes `FlowLayout` (custom SwiftUI `Layout`) and `TagChip` view.
- **SettingsView.swift** — SwiftUI form for configuring save location (with browse panel) and default tag.
- **SettingsWindowController.swift** — `NSWindowController` that hosts the `SettingsView`.

### `Tests/JotKitTests/` — test target

- **NoteServiceTests.swift** — Tests for title resolution, slug generation, tag parsing, content formatting, and file save integration.

### Other

- **scripts/bundle.sh** — Builds release binary, creates `.app` bundle with Info.plist, ad-hoc code signs.
- **.github/workflows/ci.yml** — GitHub Actions CI: builds and tests on macOS.

## Conventions

- Target: macOS 13.0+, Swift 5.9+
- Only third-party dependency is HotKey (for global shortcuts)
- Service types are `enum` (caseless) with static methods
- Preferences use `UserDefaults` via static computed properties
- Notes with explicit titles are saved as `{Title}.md`; auto-generated names use `{timestamp} {title}.md` (spaces, not dashes)
- YAML frontmatter is only added when tags are present
