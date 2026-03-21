# Desktop Notes for macOS

> **This project is abandoned and no longer maintained.** The app is fully functional as-is, but no further updates, bug fixes, or feature additions will be made. Feel free to fork it and make it your own!

A lightweight menu bar sticky notes app for macOS, built with SwiftUI and AppKit. No external dependencies.

## Features

- **Menu bar app** -- lives in the menu bar with no dock icon clutter
- Create unlimited sticky notes that float on your desktop
- Drag and resize notes anywhere, across all Spaces
- Edit note title and body with live auto-save
- Pin notes to keep them always on top
- 6 built-in color themes (Ocean, Forest, Plum, Cherry, Slate, Amber)
- Show/hide individual notes or all at once
- Export and import notes as JSON backups
- Notes persist locally and restore automatically on launch
- Keyboard shortcuts: Cmd+N (new note), Cmd+Q (quit)

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ (includes Swift 5.9)

## Building & Running

### Option 1: Xcode

1. Clone this repository:
   ```bash
   git clone https://github.com/georgekgr12/Desktop-Notes-for-OSX.git
   cd Desktop-Notes-for-OSX
   ```
2. Open `Package.swift` in Xcode (File > Open, then select `Package.swift`).
3. Xcode will resolve the package automatically.
4. Select the **StickyNotesApp** scheme from the scheme selector.
5. Click **Run** (Cmd+R).
6. The app will appear as a note icon in your menu bar.

### Option 2: Terminal (Swift CLI)

1. Clone this repository:
   ```bash
   git clone https://github.com/georgekgr12/Desktop-Notes-for-OSX.git
   cd Desktop-Notes-for-OSX
   ```
2. Build and run:
   ```bash
   swift run
   ```
3. The app will compile and launch. Look for the note icon in your menu bar.

### Creating a Standalone .app Bundle

To create a proper `.app` that you can put in your Applications folder:

1. Open `Package.swift` in Xcode.
2. Go to **Product > Archive**.
3. In the Organizer window, click **Distribute App > Copy App**.
4. Move the resulting `.app` to `/Applications/`.

Alternatively, you can build a release binary from the terminal and wrap it manually:

```bash
swift build -c release

# The binary will be at:
# .build/release/StickyNotesApp
```

To wrap it as a `.app` bundle:

```bash
APP="StickyNotesApp.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Copy the binary
cp .build/release/StickyNotesApp "$APP/Contents/MacOS/"

# Copy the icon (optional)
cp Assets/IconGen/AppIcon.icns "$APP/Contents/Resources/"

# Create Info.plist
cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>StickyNotesApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.StickyNotesApp</string>
    <key>CFBundleName</key>
    <string>Desktop Notes</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST

echo "Done! Move $APP to /Applications/ to install."
```

> **Note:** `LSUIElement` is set to `true` so the app runs as a menu bar utility without a dock icon.

## How It Works

The app runs as a menu bar accessory. Clicking the note icon in the menu bar gives you controls to:

- **New Sticky Note** -- creates a floating note window on your desktop
- **Per-note controls** -- show/hide, pin, change color theme, or delete each note
- **Show All / Hide All** -- toggle visibility of all notes at once
- **Export / Import** -- back up or restore your notes as a JSON file

Notes are saved automatically to `~/Library/Application Support/StickyNotesApp/notes.json`.

## Architecture

| File | Purpose |
|------|---------|
| `StickyNotesApp.swift` | App entry point, menu bar scene setup |
| `MenuBarView.swift` | Menu bar UI and user actions |
| `Note.swift` | Data model with color palette definitions |
| `NoteStore.swift` | JSON persistence, import/export, state management |
| `NoteWindowManager.swift` | Window lifecycle for all notes |
| `NoteWindowController.swift` | Individual NSWindow setup (floating, pinned, draggable) |
| `StickyNoteView.swift` | SwiftUI note editor view |
| `Color+Hex.swift` | Hex color parsing utilities |

## License

This project is licensed under the [MIT License](LICENSE).
