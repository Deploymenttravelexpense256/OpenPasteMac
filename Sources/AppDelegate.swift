import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

private func hotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return noErr }
    let d = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async { d.toggleShelf() }
    return noErr
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var store = ClipboardStore()
    private var clipMonitor: ClipboardMonitor!
    private var hotKeyRef: EventHotKeyRef?
    private var carbonHandlerRef: EventHandlerRef?
    private var keyMonitor: Any?
    private var clickOutsideMonitor: Any?

    private let shelfHeight: CGFloat = 295

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        registerHotKey()

        clipMonitor = ClipboardMonitor(store: store)
        clipMonitor.start()

        requestAccessibilityIfNeeded()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let img = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: "OpenPasteMac")
        img?.isTemplate = true
        statusItem.button?.image = img
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusButtonClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        event.type == .rightMouseUp ? showContextMenu(sender) : toggleShelf()
    }

    private func showContextMenu(_ button: NSStatusBarButton) {
        if panel.isVisible { hideShelf(animated: false) }
        let menu = NSMenu()

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled ? .on : .off
        launchItem.isEnabled = isRunningAsBundle
        menu.addItem(launchItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit OpenPasteMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.popUp(positioning: nil, at: NSPoint(x: -1, y: button.bounds.height + 4), in: button)
    }

    // MARK: - Launch at Login

    private var isRunningAsBundle: Bool { Bundle.main.bundleIdentifier != nil }
    private var isLaunchAtLoginEnabled: Bool { SMAppService.mainApp.status == .enabled }

    @objc private func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch { NSApp.presentError(error) }
    }

    // MARK: - Bottom Shelf Panel

    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: shelfHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let view = ClipboardShelfView(
            store: store,
            onPaste:          { [weak self] item in self?.pasteItem(item) },
            onPastePlainText: { [weak self] item in self?.pastePlainText(item) },
            onCopyOnly:       { [weak self] item in self?.copyOnly(item) },
            onDismiss:        { [weak self] in self?.hideShelf(animated: true) }
        )
        panel.contentView = NSHostingView(rootView: view)
    }

    // MARK: - Hot Key

    private func registerHotKey() {
        unregisterHotKey()

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyHandler, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), &carbonHandlerRef)

        var hkID = EventHotKeyID()
        hkID.signature = OSType(0x636C6970) // 'clip'
        hkID.id = 1

        let sm = ShortcutManager.shared
        RegisterEventHotKey(UInt32(sm.keyCode), UInt32(sm.modifiers), hkID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
    }

    // MARK: - Toggle

    @objc func toggleShelf() {
        panel.isVisible ? hideShelf(animated: true) : showShelf()
    }

    private func showShelf() {
        store.searchQuery = ""
        store.selectedIndex = 0
        store.isSearching = false

        // Remember which app was active so "Paste to X" knows the target
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            store.previousFrontApp = SourceApp(name: app.localizedName ?? "App",
                                               bundleIdentifier: app.bundleIdentifier)
        }

        let screen = targetScreen()
        let sf = screen.frame
        let targetFrame = NSRect(x: sf.minX, y: sf.minY, width: sf.width, height: shelfHeight)
        let startFrame  = NSRect(x: sf.minX, y: sf.minY - shelfHeight, width: sf.width, height: shelfHeight)

        panel.setFrame(startFrame, display: false)
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.26
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
        }

        installKeyMonitor()
        installClickOutsideMonitor()
    }

    func hideShelf(animated: Bool) {
        guard panel.isVisible else { return }
        removeKeyMonitor()
        removeClickOutsideMonitor()

        if animated {
            let f = panel.frame
            let offscreen = NSRect(x: f.minX, y: f.minY - f.height, width: f.width, height: f.height)
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.20
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(offscreen, display: true)
            }, completionHandler: {
                self.panel.orderOut(nil)
            })
        } else {
            panel.orderOut(nil)
        }
    }

    private func targetScreen() -> NSScreen {
        // Prefer screen containing the mouse cursor
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main ?? NSScreen.screens[0]
    }

    // MARK: - Click Outside

    private func installClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.panel.isVisible else { return }
            self.hideShelf(animated: true)
        }
    }

    private func removeClickOutsideMonitor() {
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m); clickOutsideMonitor = nil }
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            self?.handleKey(e) ?? e
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        guard panel.isVisible else { return event }

        switch event.keyCode {
        case 123: store.moveLeft();  return nil   // ←
        case 124: store.moveRight(); return nil   // →
        case 36, 76:                              // Return / Numpad Enter
            if let item = store.selectedItem { pasteItem(item) }
            return nil
        case 53:                                  // Escape
            hideShelf(animated: true)
            return nil
        default:
            if event.modifierFlags.contains(.command) {
                let map: [UInt16: Int] = [18:0, 19:1, 20:2, 21:3, 23:4, 22:5, 26:6, 28:7, 25:8]
                if let idx = map[event.keyCode], idx < store.filteredItems.count {
                    pasteItem(store.filteredItems[idx])
                    return nil
                }
            }
            return event
        }
    }

    // MARK: - Paste

    private func pasteItem(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let t):   pb.setString(t, forType: .string)
        case .url(let u):    pb.setString(u.absoluteString, forType: .string)
        case .image(let img): pb.writeObjects([img])
        case .file(let u):   pb.writeObjects([u as NSURL])
        }
        clipMonitor.suppressNextChange()
        hideShelf(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { self.simulatePaste() }
    }

    func pastePlainText(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content.displayText, forType: .string)
        clipMonitor.suppressNextChange()
        hideShelf(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { self.simulatePaste() }
    }

    func copyOnly(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let t):    pb.setString(t, forType: .string)
        case .url(let u):     pb.setString(u.absoluteString, forType: .string)
        case .image(let img): pb.writeObjects([img])
        case .file(let u):    pb.writeObjects([u as NSURL])
        }
        clipMonitor.suppressNextChange()
    }

    private func simulatePaste() {
        guard AXIsProcessTrusted() else { return }
        let src = CGEventSource(stateID: .hidSystemState)
        let dn = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        dn?.flags = .maskCommand; up?.flags = .maskCommand
        dn?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }
}
