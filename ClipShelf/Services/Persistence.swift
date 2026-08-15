import AppKit

enum Persistence {
    static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ClipShelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

/// Simple JSON-file-backed store for an array of Codable items. Not for large data —
/// images are kept out-of-line via ImageCache and referenced by filename.
final class JSONFileStore<T: Codable> {
    private let fileURL: URL

    init(fileName: String) {
        fileURL = Persistence.applicationSupportDirectory().appendingPathComponent(fileName)
    }

    func load() -> [T] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([T].self, from: data)) ?? []
    }

    func save(_ items: [T]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// Saves/loads images as PNG files in a named subfolder of the app support directory.
final class ImageCache {
    private let directory: URL

    init(subfolder: String) {
        directory = Persistence.applicationSupportDirectory().appendingPathComponent(subfolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    @discardableResult
    func save(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        let fileName = "\(UUID().uuidString).png"
        do {
            try png.write(to: url(for: fileName))
            return fileName
        } catch {
            return nil
        }
    }

    func load(_ fileName: String) -> NSImage? {
        NSImage(contentsOf: url(for: fileName))
    }

    func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
