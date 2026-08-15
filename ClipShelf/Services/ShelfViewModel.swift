import AppKit
import UniformTypeIdentifiers

/// Holds the items currently "parked" on the shelf. The shelf panel is revealed by
/// DragShakeDetector or the manual menu item and then stays open until the user closes
/// it explicitly — `isTargeted` only drives the drop-highlight, nothing auto-hides.
final class ShelfViewModel: ObservableObject {
    @Published var items: [ShelfItem] = []
    @Published var isTargeted: Bool = false

    private let store: ShelfStore

    var onHideRequested: (() -> Void)?
    var onDragBegin: (() -> Void)?
    var onDragChanged: (() -> Void)?

    init(store: ShelfStore) {
        self.store = store
        self.items = store.load()
    }

    func remove(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        store.deleteImageIfNeeded(item)
        store.save(items)
    }

    func clear() {
        for item in items {
            store.deleteImageIfNeeded(item)
        }
        items = []
        store.save(items)
    }

    func image(for item: ShelfItem) -> NSImage? {
        store.image(for: item)
    }

    /// The URL/text a drag session should hand out when this item is dragged elsewhere
    /// (e.g. onto Finder or into another app).
    func dragItemProvider(for item: ShelfItem) -> NSItemProvider {
        switch item.kind {
        case .fileURL:
            guard let url = item.fileURL else { return NSItemProvider() }
            return DragProviders.file(url)
        case .image:
            guard let url = store.imageFileURL(for: item) else { return NSItemProvider() }
            return DragProviders.file(url, suggestedName: "Bild.png")
        case .text:
            return DragProviders.text(item.text ?? "")
        }
    }

    /// File URLs to hand to AirDrop (or any file-based share sheet) for this item.
    func airDropURLs(for item: ShelfItem) -> [URL] {
        switch item.kind {
        case .fileURL:
            guard let url = item.fileURL else { return [] }
            return [url]
        case .image:
            guard let url = store.imageFileURL(for: item) else { return [] }
            return [url]
        case .text:
            guard let text = item.text, let url = ShareSender.temporaryTextFile(text) else { return [] }
            return [url]
        }
    }

    @discardableResult
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            addItem(from: provider)
        }
        return true
    }

    private func addItem(from provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let directURL = item as? URL {
                    url = directURL
                } else {
                    url = nil
                }
                guard let self, let url else { return }
                DispatchQueue.main.async { self.appendFileURL(url) }
            }
            return
        }

        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { [weak self] image, _ in
                guard let self, let image = image as? NSImage else { return }
                DispatchQueue.main.async { self.appendImage(image) }
            }
            return
        }

        if provider.canLoadObject(ofClass: NSString.self) {
            _ = provider.loadObject(ofClass: NSString.self) { [weak self] string, _ in
                guard let self, let string = string as? String else { return }
                DispatchQueue.main.async { self.appendText(string) }
            }
            return
        }
    }

    private func appendFileURL(_ url: URL) {
        guard !items.contains(where: { $0.kind == .fileURL && $0.fileURL == url }) else { return }
        items.insert(ShelfItem(kind: .fileURL, fileURL: url, displayName: url.lastPathComponent), at: 0)
        store.save(items)
    }

    private func appendImage(_ image: NSImage) {
        guard let fileName = store.imageCache.save(image) else { return }
        items.insert(ShelfItem(kind: .image, imageFileName: fileName, displayName: "Bild"), at: 0)
        store.save(items)
    }

    private func appendText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.insert(ShelfItem(kind: .text, text: text, displayName: text), at: 0)
        store.save(items)
    }
}
