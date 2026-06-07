import SwiftUI
import AppKit

struct ItemPreviewOverlay: View {
    let item: ClipboardItem
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                previewHeader
                Divider().background(Color.white.opacity(0.1))
                previewContent
            }
            .frame(maxWidth: previewWidth, maxHeight: previewHeight)
            .background(Color(red: 0.10, green: 0.13, blue: 0.20))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.7), radius: 40, y: 12)
        }
    }

    // MARK: - Header

    private var previewHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: item.content.systemIcon)
                    .font(.system(size: 13))
                    .foregroundColor(item.content.headerColor)
                Text(item.label ?? item.content.typeLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            if let app = item.sourceApp {
                HStack(spacing: 4) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Text("from \(app.name)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(item.timeAgo)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Content

    @ViewBuilder
    private var previewContent: some View {
        switch item.content {
        case .text(let t):
            ScrollView {
                Text(t)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }

        case .image(let img):
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
            }

        case .url(let url):
            VStack(alignment: .leading, spacing: 14) {
                if let meta = item.linkMetadata {
                    if let preview = meta.previewImage {
                        Image(nsImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    HStack(spacing: 8) {
                        if let fav = meta.favicon {
                            Image(nsImage: fav)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(meta.domain ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    if let title = meta.title {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                Text(url.absoluteString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.8))
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)

        case .file(let url):
            VStack(spacing: 16) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 80, height: 80)
                Text(url.lastPathComponent)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(url.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    // MARK: - Sizing

    private var previewWidth: CGFloat {
        if case .image(let img) = item.content {
            return min(img.size.width + 24, 800)
        }
        return 600
    }

    private var previewHeight: CGFloat {
        if case .image(let img) = item.content {
            return min(img.size.height + 60, 600)
        }
        return 420
    }
}
