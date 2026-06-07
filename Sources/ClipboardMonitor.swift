import AppKit

class ClipboardMonitor {
    private weak var store: ClipboardStore?
    private var timer: Timer?
    private var lastChangeCount: Int
    private var suppressNext = false
    private var lastSourceApp: SourceApp?

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount

        // Track which app the user was in before copying
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.check()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() { timer?.invalidate(); timer = nil }

    func suppressNextChange() { suppressNext = true }

    @objc private func activeAppChanged(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        lastSourceApp = SourceApp(name: app.localizedName ?? "Unknown", bundleIdentifier: app.bundleIdentifier)
    }

    private func check() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if suppressNext { suppressNext = false; return }

        guard var item = read() else { return }
        item = ClipboardItem(id: item.id, timestamp: item.timestamp,
                             content: item.content, isPinned: false,
                             sourceApp: lastSourceApp)

        DispatchQueue.main.async { [weak self] in
            self?.store?.add(item)
        }
    }

    private func read() -> ClipboardItem? {
        let pb = NSPasteboard.general

        if let string = pb.string(forType: .string), !string.isEmpty {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: trimmed),
               let scheme = url.scheme,
               ["http", "https"].contains(scheme),
               url.host != nil {
                return ClipboardItem(content: .url(url))
            }
            return ClipboardItem(content: .text(string))
        }

        if let image = NSImage(pasteboard: pb) {
            return ClipboardItem(content: .image(image))
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL],
           let first = urls.first, first.isFileURL {
            return ClipboardItem(content: .file(first))
        }

        return nil
    }
}
