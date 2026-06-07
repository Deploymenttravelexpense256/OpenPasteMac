import SwiftUI
import AppKit

struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    var onPaste: () -> Void
    var onPin: () -> Void
    var onDelete: () -> Void
    var onAddToPinboard: (Pinboard) -> Void
    let pinboards: [Pinboard]

    @State private var isHovered = false

    static let cardWidth: CGFloat  = 210
    static let cardHeight: CGFloat = 220

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            cardBody
            cardFooter
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .background(Color(red: 0.09, green: 0.115, blue: 0.18))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSelected ? Color(red: 0.22, green: 0.55, blue: 1.0) : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 2.5 : 0.5
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.6 : 0.35), radius: isSelected ? 12 : 6, y: 4)
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture(count: 1) { onPaste() }
        .contextMenu { contextMenuItems }
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content.typeLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Text(item.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
            appIcon
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(item.content.headerColor)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let nsImage = item.sourceApp?.icon {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 26, height: 26)
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var cardBody: some View {
        switch item.content {
        case .text(let str):
            textBody(str)
        case .url(let url):
            linkBody(url)
        case .image(let img):
            imageBody(img)
        case .file(let url):
            fileBody(url)
        }
    }

    private func textBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private func linkBody(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let meta = item.linkMetadata {
                HStack(spacing: 8) {
                    if let favicon = meta.favicon {
                        Image(nsImage: favicon)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 20, height: 20)
                    }
                    Text(meta.domain ?? url.host ?? "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                if let preview = meta.previewImage {
                    Image(nsImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }

                if let title = meta.title {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
            } else {
                // Loading state
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.3))
                    Text(url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                Text(url.absoluteString)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func imageBody(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private func fileBody(_ url: URL) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 44, height: 44)
            Text(url.lastPathComponent)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
    }

    // MARK: - Footer

    private var cardFooter: some View {
        HStack {
            Text(item.footerLabel)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .lineLimit(1)
            Spacer()
            HStack(spacing: 3) {
                Image(systemName: "text.justify")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.25))
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(isSelected ? 0.9 : 0.35))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Paste") { onPaste() }
        Button(item.isPinned ? "Unpin" : "Pin") { onPin() }

        if !pinboards.isEmpty {
            Menu("Add to Pinboard") {
                ForEach(pinboards) { board in
                    Button(board.name) { onAddToPinboard(board) }
                }
            }
        }

        Divider()
        Button("Delete", role: .destructive) { onDelete() }
    }
}
