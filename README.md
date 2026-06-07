# Clipboard History

A lightweight macOS clipboard manager — menu bar icon, global hotkey, zero friction.

## Behavior

- **Click outside** the panel to dismiss it
- Pressing the hotkey again also dismisses it
- Clicking the menu bar icon toggles the panel
- Right-click the menu bar icon for Settings / Quit

## Shortcuts

| Shortcut | Action |
|---|---|
| ⌘ Shift V | Toggle panel (works system-wide) |
| ↑ / ↓ | Navigate list |
| ↵ Enter | Paste selected item |
| ⌘ 1–9 | Paste item 1–9 directly |
| Esc | Close panel |
| Click item | Paste item |

---

## Installation (permanent — runs as a real app)

### Option A — One command

```bash
make install
```

This builds a release binary, packages it as `ClipboardHistory.app`, copies it to
`/Applications`, and opens it.

### Option B — Step by step

```bash
# 1. Build the .app bundle
./scripts/build-app.sh

# 2. Copy to Applications
cp -r dist/ClipboardHistory.app /Applications/

# 3. Open it
open /Applications/ClipboardHistory.app
```

### Option C — DMG (to share with others)

```bash
make dmg
# Produces: dist/ClipboardHistory.dmg
```

Distribute the DMG. Recipients double-click it and drag the app to Applications.

---

## First-launch setup

### 1 — Accessibility (required for auto-paste)

On the first launch a dialog will appear asking to grant **Accessibility** access.
Click **Open System Settings** and enable Clipboard History in the list.

> If you skip this, the app still works — it puts the item on your clipboard —
> you just need to press ⌘V yourself.

Path: **System Settings → Privacy & Security → Accessibility**

### 2 — Launch at Login (optional)

So the app is always running without you needing to start it manually:

1. Make sure the app is installed in `/Applications` (not just run from the project folder)
2. Right-click the **menu bar icon** → **Launch at Login**

This uses macOS's built-in login item system (`SMAppService`). It only works when
running as a proper `.app` bundle from Applications.

---

## Development

```bash
# Quick run (debug build, no install needed)
make run

# Or manually
swift build
.build/debug/ClipboardHistory
```

## Project layout

```
Sources/
├── main.swift              Entry point
├── AppDelegate.swift       Menu bar, panel, hotkeys, paste, click-outside
├── ClipboardItem.swift     Data model
├── ClipboardStore.swift    Observable store + disk persistence
├── ClipboardMonitor.swift  NSPasteboard polling
└── Views/
    ├── ClipboardPanelView.swift  Main SwiftUI panel
    ├── ClipboardItemRow.swift    List row
    └── VisualEffectView.swift    Vibrancy bridge

scripts/
├── build-app.sh   Builds release binary + assembles .app bundle → dist/
└── create-dmg.sh  Wraps the .app in a distributable DMG → dist/
```

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools: `xcode-select --install`
