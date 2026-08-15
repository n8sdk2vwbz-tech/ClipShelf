import AppKit

/// Shared NSItemProvider construction for dragging files/text out of ClipShelf's rows.
enum DragProviders {
    /// `NSItemProvider(contentsOf:)` is documented to derive the suggested name from the
    /// URL automatically, but that didn't hold up in practice — some destinations fell
    /// back to a generic "PDF document.pdf"-style placeholder instead of the real name.
    /// So the name is now always set explicitly rather than relying on that.
    static func file(_ url: URL, suggestedName: String? = nil) -> NSItemProvider {
        let provider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
        provider.suggestedName = suggestedName ?? url.lastPathComponent
        return provider
    }

    static func text(_ string: String) -> NSItemProvider {
        NSItemProvider(object: string as NSString)
    }
}
