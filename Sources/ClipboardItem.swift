import AppKit
import SwiftUI
import Foundation

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    var content: Content
    var isPinned: Bool
    var sourceApp: SourceApp?
    var linkMetadata: LinkMetadata?    // populated async for .url items
    var label: String?                 // user-set display name

    enum Content: Equatable {
        case text(String)
        case url(URL)
        case image(NSImage)
        case file(URL)

        var displayText: String {
            switch self {
            case .text(let s): return s
            case .url(let u): return u.absoluteString
            case .image: return "[Image]"
            case .file(let u): return u.lastPathComponent
            }
        }

        var systemIcon: String {
            switch self {
            case .text: return "doc.text.fill"
            case .url: return "link"
            case .image: return "photo.fill"
            case .file: return "doc.fill"
            }
        }

        var typeLabel: String {
            switch self {
            case .text: return "Text"
            case .url: return "Link"
            case .image: return "Image"
            case .file: return "File"
            }
        }

        var headerColor: Color {
            switch self {
            case .text: return Color(red: 0.145, green: 0.310, blue: 0.635)
            case .url:  return Color(red: 0.145, green: 0.310, blue: 0.635)
            case .image: return Color(red: 0.118, green: 0.455, blue: 0.259)
            case .file: return Color(red: 0.502, green: 0.255, blue: 0.055)
            }
        }

        static func == (lhs: Content, rhs: Content) -> Bool {
            switch (lhs, rhs) {
            case (.text(let a), .text(let b)): return a == b
            case (.url(let a), .url(let b)): return a == b
            case (.file(let a), .file(let b)): return a == b
            case (.image, .image): return false
            default: return false
            }
        }
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), content: Content,
         isPinned: Bool = false, sourceApp: SourceApp? = nil, label: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.isPinned = isPinned
        self.sourceApp = sourceApp
        self.label = label
    }

    var timeAgo: String {
        let d = Date().timeIntervalSince(timestamp)
        if d < 60   { return "now" }
        if d < 3600 { return "\(Int(d/60))m ago" }
        if d < 86400 { return "\(Int(d/3600))h ago" }
        return "\(Int(d/86400))d ago"
    }

    var footerLabel: String {
        switch content {
        case .text(let s): return "\(s.count) characters"
        case .url(let u): return u.host ?? u.absoluteString
        case .image(let img):
            let s = img.size
            return "\(Int(s.width)) × \(Int(s.height))"
        case .file(let u): return u.pathExtension.uppercased()
        }
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool { lhs.id == rhs.id }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
