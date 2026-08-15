import AppKit

/// Shared NSItemProvider construction for dragging files/text out of ClipShelf's rows.
enum DragProviders {
    /// `NSItemProvider(contentsOf:)` — the plain convenience initializer — correctly
    /// derives both the file's name and type from the URL itself. An earlier attempt to
    /// hand-roll this via `registerFileRepresentation` (to fix drags not landing in some
    /// apps) instead broke the filename: destinations ended up naming files after just
    /// the type, doubled up, e.g. "pdf.pdf". Back to the simple, correct version.
    static func file(_ url: URL, suggestedName: String? = nil) -> NSItemProvider {
        let provider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
        if let suggestedName {
            provider.suggestedName = suggestedName
        }
        return provider
    }

    static func text(_ string: String) -> NSItemProvider {
        NSItemProvider(object: string as NSString)
    }
}
