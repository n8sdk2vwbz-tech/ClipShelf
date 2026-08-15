import SwiftUI

struct HistoryListView: View {
    @ObservedObject var monitor: ClipboardMonitor
    let store: ClipboardStore
    @ObservedObject var shelfViewModel: ShelfViewModel

    var onPasteSelected: (ClipboardItem) -> Void
    var onCopySelected: (ClipboardItem) -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void
    var onClose: () -> Void
    var onDragBegin: () -> Void
    var onDragChanged: () -> Void

    @State private var query: String = ""
    @State private var hoveredID: UUID?
    @State private var shelfIsTargeted = false

    private let shelfDropTypes: [String] = ["public.file-url", "public.image", "public.text", "public.url"]

    private var filteredItems: [ClipboardItem] {
        guard !query.isEmpty else { return monitor.items }
        return monitor.items.filter { $0.previewTitle.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)

            shelfSection
            Divider().opacity(0.5)

            searchField
            Divider().opacity(0.5)

            historyList
            Divider().opacity(0.5)

            footer
        }
        .frame(width: 340, height: 460)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.regularMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text("ClipShelf")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.hoverIcon(tint: .secondary))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .windowDraggable(onBegin: onDragBegin, onChanged: onDragChanged)
    }

    private var shelfSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Ablage", count: shelfViewModel.items.count)
            if shelfViewModel.items.isEmpty {
                HStack {
                    Spacer()
                    Text("Dateien, Bilder oder Text hierher ziehen")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 10)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(shelfViewModel.items) { item in
                        ShelfItemRowView(item: item, viewModel: shelfViewModel) {
                            shelfViewModel.remove(item)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(shelfIsTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(shelfIsTargeted ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeOut(duration: 0.12), value: shelfIsTargeted)
        .onDrop(of: shelfDropTypes, isTargeted: $shelfIsTargeted) { providers in
            shelfViewModel.handleDrop(providers: providers)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Suchen…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.secondary.opacity(0.09)))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var historyList: some View {
        Group {
            if filteredItems.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                    Text(monitor.items.isEmpty ? "Noch nichts kopiert" : "Keine Treffer")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems) { item in
                            HistoryRowView(
                                item: item,
                                store: store,
                                isSelected: hoveredID == item.id,
                                onPin: { monitor.togglePin(item) },
                                onDelete: { monitor.remove(item) }
                            )
                            .onHover { isHovering in
                                hoveredID = isHovering ? item.id : (hoveredID == item.id ? nil : hoveredID)
                            }
                            .onTapGesture(count: 2) { onCopySelected(item) }
                            .onTapGesture(count: 1) { onPasteSelected(item) }
                        }
                    }
                    .padding(6)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Button("Alle löschen") { monitor.clearAll() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.hoverIcon)

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(.hoverIcon(tint: .red))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
