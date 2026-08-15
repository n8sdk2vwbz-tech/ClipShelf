import AppKit

/// Sharing files out of ClipShelf via the system's native share mechanisms — the same
/// ones Finder's Share menu uses — rather than drag-and-drop. Some destination apps
/// (Messages in particular) don't reliably accept file drags coming from a third-party
/// app's synthesized drag session, but they do support NSSharingService, since that's
/// the exact same path a Finder-initiated share takes.
enum ShareSender {
    static func sendViaAirDrop(_ urls: [URL]) {
        send(urls, using: .sendViaAirDrop)
    }

    static func sendViaMessages(_ urls: [URL]) {
        send(urls, using: .composeMessage)
    }

    private static func send(_ urls: [URL], using name: NSSharingService.Name) {
        guard !urls.isEmpty, let service = NSSharingService(named: name) else { return }
        service.perform(withItems: urls)
    }

    static func temporaryTextFile(_ text: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ClipShelf-Share", isDirectory: true)
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
