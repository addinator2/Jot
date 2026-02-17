# jot

A lightweight macOS menu bar app for quick note capture. Jot down thoughts instantly with a global keyboard shortcut — notes are saved as Markdown files to a directory of your choice.

## Features

- Global shortcut (Cmd+Shift+N) to capture notes from anywhere
- Saves notes as Markdown with optional YAML frontmatter tags
- Configurable save directory and default tag
- Floating panel with frosted glass appearance
- Runs as a menu bar app (no Dock icon)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/furst/Jot/main/scripts/install.sh | bash
```

This clones the repo, builds from source, and installs `jot.app` into `/Applications`.

**Requirements:** macOS 13.0+ with Xcode Command Line Tools (`xcode-select --install`).

### Manual build

```bash
git clone https://github.com/furst/Jot.git
cd Jot
./scripts/bundle.sh
open .build/bundle/jot.app
```

## Usage

- **Left-click** the menu bar icon to open the note editor
- **Right-click** for the menu (Settings, Quit)
- **Cmd+Shift+N** to open from anywhere (requires Accessibility permission)
- **Cmd+Return** to save a note
- **Escape** to dismiss

## Settings

- **Save Location** — directory where notes are saved (default: `~/Documents`)
- **Default Tag** — automatically added to every note's frontmatter

## License

[MIT](LICENSE)
