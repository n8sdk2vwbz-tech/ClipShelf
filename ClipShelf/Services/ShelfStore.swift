import AppKit

final class ShelfStore {
    private let fileStore = JSONFileStore<ShelfItem>(fileName: "shelf.json")
    let imageCache = ImageCache(subfolder: "ShelfImages")

    func load() -> [ShelfItem] {
        fileStore.load()
    }

    func save(_ items: [ShelfItem]) {
        fileStore.save(items)
    }

    func image(for item: ShelfItem) -> NSImage? {
        guard let fileName = item.imageFileName else { return nil }
        return imageCache.load(fileName)
    }

    func imageFileURL(for item: ShelfItem) -> URL? {
        guard let fileName = item.imageFileName else { return nil }
        return imageCache.url(for: fileName)
    }

    func deleteImageIfNeeded(_ item: ShelfItem) {
        guard let fileName = item.imageFileName else { return }
        imageCache.delete(fileName)
    }
}
