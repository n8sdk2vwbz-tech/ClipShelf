import AppKit
import SwiftUI

struct ShelfItemRowView: View {
    let item: ShelfItem
    @ObservedObject var viewModel: ShelfViewModel
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            thumbnail.frame(width: 26, height: 26)

            Text(item.displayName)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.hoverIcon(tint: .secondary))
            .opacity(isHovering ? 1 : 0.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovering ? Color.secondary.opacity(0.14) : Color.secondary.opacity(0.07))
        )
        .animation(.easeOut(duration: 0.1), value: isHovering)
        .onHover { isHovering = $0 }
        .onDrag { viewModel.dragItemProvider(for: item) }
        .contextMenu {
            Button {
                ShareSender.sendViaMessages(viewModel.airDropURLs(for: item))
            } label: {
                Label("Über Nachrichten senden…", systemImage: "message")
            }
            Button {
                ShareSender.sendViaAirDrop(viewModel.airDropURLs(for: item))
            } label: {
                Label("Über AirDrop senden…", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch item.kind {
        case .fileURL:
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.fileURL?.path ?? "/"))
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .image:
            if let nsImage = viewModel.image(for: item) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            } else {
                Image(systemName: "photo")
            }
        case .text:
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.blue.opacity(0.15))
                .overlay(Image(systemName: "text.alignleft").font(.system(size: 11)).foregroundStyle(.blue))
        }
    }
}
