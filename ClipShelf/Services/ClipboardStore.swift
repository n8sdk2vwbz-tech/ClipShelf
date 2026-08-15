import AppKit

/// Persists clipboard history to disk and owns the on-disk image cache for image items.
final class ClipboardStore {
    private let fileStore = JSONFileStore<ClipboardItem>(fileName: "history.json")
    let imageCache = ImageCache(subfolder: "ClipboardImages")

    func load() -> [ClipboardItem] {
        fileStore.load()
    }

    func save(_ items: [ClipboardItem]) {
        fileStore.save(items)
    }

    func image(for item: ClipboardItem) -> NSImage? {
        guard let fileName = item.imageFileName else { return nil }
        return imageCache.load(fileName)
    }

    func imageFileURL(for item: ClipboardItem) -> URL? {
        guard let fileName = item.imageFileName else { return nil }
        return imageCache.url(for: fileName)
    }

    func deleteImageIfNeeded(_ item: ClipboardItem, keepAmong remaining: [ClipboardItem]) {
        guard let fileName = item.imageFileName else { return }
        let stillReferenced = remaining.contains { $0.imageFileName == fileName }
        guard !stillReferenced else { return }
        imageCache.delete(fileName)
    }

    /// What a drag session should hand out when a history row is dragged elsewhere —
    /// onto the shelf, into Finder, or any other app. `.onDrag` only supports a single
    /// item provider, so a multi-file entry drags out just its first file.
    func dragItemProvider(for item: ClipboardItem) -> NSItemProvider {
        switch item.kind {
        case .text:
            return DragProviders.text(item.text ?? "")
        case .image:
            guard let url = imageFileURL(for: item) else { return NSItemProvider() }
            return DragProviders.file(url, suggestedName: "Bild.png")
        case .fileURLs:
            guard let url = item.fileURLs?.first else { return NSItemProvider() }
            return DragProviders.file(url)
        }
    }

    /// File URLs to hand to AirDrop (or any file-based share sheet) for this item.
    /// Unlike drag-out, this can carry every file of a multi-file entry at once.
    func airDropURLs(for item: ClipboardItem) -> [URL] {
        switch item.kind {
        case .text:
            guard let text = item.text, let url = AirDropSender.temporaryTextFile(text) else { return [] }
            return [url]
        case .image:
            guard let url = imageFileURL(for: item) else { return [] }
            return [url]
        case .fileURLs:
            return item.fileURLs ?? []
        }
    }
}
