import AppKit
import LinkPresentation

struct LinkMetadata: Equatable {
    var title: String?
    var domain: String?
    var favicon: NSImage?
    var previewImage: NSImage?

    static func == (lhs: LinkMetadata, rhs: LinkMetadata) -> Bool {
        lhs.title == rhs.title && lhs.domain == rhs.domain
    }
}

actor LinkPreviewService {
    static let shared = LinkPreviewService()
    private var cache: [URL: LinkMetadata] = [:]

    func fetch(for url: URL) async -> LinkMetadata {
        if let cached = cache[url] { return cached }

        var metadata = LinkMetadata(
            title: nil,
            domain: url.host?.replacingOccurrences(of: "www.", with: ""),
            favicon: nil,
            previewImage: nil
        )

        do {
            let provider = LPMetadataProvider()
            provider.timeout = 8
            let lp = try await provider.startFetchingMetadata(for: url)
            metadata.title = lp.title

            if let iconProvider = lp.iconProvider {
                metadata.favicon = await loadImage(iconProvider)
            }
            if let imageProvider = lp.imageProvider {
                metadata.previewImage = await loadImage(imageProvider)
            }
        } catch {
            metadata.favicon = await fetchGoogleFavicon(for: url)
        }

        cache[url] = metadata
        return metadata
    }

    private func loadImage(_ provider: NSItemProvider) async -> NSImage? {
        await withCheckedContinuation { cont in
            provider.loadObject(ofClass: NSImage.self) { obj, _ in
                cont.resume(returning: obj as? NSImage)
            }
        }
    }

    private func fetchGoogleFavicon(for url: URL) async -> NSImage? {
        guard let host = url.host,
              let fURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64"),
              let (data, _) = try? await URLSession.shared.data(from: fURL) else { return nil }
        return NSImage(data: data)
    }
}
