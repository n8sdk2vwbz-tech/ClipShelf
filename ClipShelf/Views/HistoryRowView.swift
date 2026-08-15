import SwiftUI

struct HistoryRowView: View {
    let item: ClipboardItem
    let store: ClipboardStore
    let isSelected: Bool
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5))
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    if let sourceAppName = item.sourceAppName {
                        Text(sourceAppName)
                    }
                    Text("· \(item.date.formatted(date: .omitted, time: .shortened))")
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                Button(action: onPin) {
                    Image(systemName: item.pinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.hoverIcon(tint: item.pinned ? .accentColor : .secondary))

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.hoverIcon)
            }
            .opacity(isSelected || item.pinned ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .animation(.easeOut(duration: 0.1), value: isSelected)
        .contentShape(Rectangle())
        .onDrag { store.dragItemProvider(for: item) }
        .contextMenu {
            Button {
                AirDropSender.send(store.airDropURLs(for: item))
            } label: {
                Label("Über AirDrop senden…", systemImage: "square.and.arrow.up")
            }
        }
    }

    private var title: String {
        let text = item.previewTitle
        return text.isEmpty ? "(leer)" : text
    }

    private var kindColor: Color {
        switch item.kind {
        case .text: return .blue
        case .image: return .purple
        case .fileURLs: return .orange
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch item.kind {
        case .text:
            iconChip("text.alignleft")
        case .image:
            if let nsImage = store.image(for: item) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            } else {
                iconChip("photo")
            }
        case .fileURLs:
            iconChip("doc.on.doc")
        }
    }

    private func iconChip(_ systemName: String) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(kindColor.opacity(0.15))
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 12.5))
                    .foregroundStyle(kindColor)
            )
    }
}
