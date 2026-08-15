import AppKit

/// AirDrop only accepts file-like items via NSSharingService, so plain text first gets
/// written out to a throwaway file.
enum AirDropSender {
    static func send(_ urls: [URL]) {
        guard !urls.isEmpty, let service = NSSharingService(named: .sendViaAirDrop) else { return }
        service.perform(withItems: urls)
    }

    static func temporaryTextFile(_ text: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ClipShelf-AirDrop", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(UUID().uuidString).txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
