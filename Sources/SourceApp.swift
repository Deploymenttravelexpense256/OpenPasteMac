import AppKit

struct SourceApp: Equatable {
    let name: String
    let bundleIdentifier: String?

    var icon: NSImage? {
        guard let id = bundleIdentifier else { return nil }
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            return app.icon
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    static func == (lhs: SourceApp, rhs: SourceApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}
