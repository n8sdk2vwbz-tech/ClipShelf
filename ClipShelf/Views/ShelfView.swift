import SwiftUI

/// Dropover-style shelf tray. ShelfPanelController shows this when the user shakes an
/// item they're currently dragging (or picks the manual menu item), positioned right
/// near the cursor so the drag can continue straight onto it. Once open it stays put —
/// only the ✕ button or the menu toggle closes it. The header doubles as a drag handle
/// so the tray can be nudged out of the way.
struct ShelfView: View {
    @ObservedObject var viewModel: ShelfViewModel

    private let dropTypes: [String] = ["public.file-url", "public.image", "public.text", "public.url"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.accentColor)
                Text("Ablage")
                    .font(.system(size: 11.5, weight: .semibold))
                Spacer()
                if !viewModel.items.isEmpty {
                    Button("Leeren") { viewModel.clear() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Button(action: { viewModel.onHideRequested?() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.hoverIcon(tint: .secondary))
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .windowDraggable(
                onBegin: { viewModel.onDragBegin?() },
                onChanged: { viewModel.onDragChanged?() }
            )

            Divider().opacity(0.5)

            if viewModel.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                    Text("Hier ablegen")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.items) { item in
                            ShelfItemRowView(item: item, viewModel: viewModel) {
                                viewModel.remove(item)
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 208, height: 320)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.regularMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(viewModel.isTargeted ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: viewModel.isTargeted ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeOut(duration: 0.12), value: viewModel.isTargeted)
        .onDrop(of: dropTypes, isTargeted: $viewModel.isTargeted) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }
}
