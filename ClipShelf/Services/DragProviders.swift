import AppKit

/// Shared NSItemProvider construction for dragging files/text out of ClipShelf's rows.
enum DragProviders {
    /// `NSItemProvider(contentsOf:)` also registers the file's UTI, and Finder appends
    /// that type's preferred extension onto whatever `suggestedName` it's given — even
    /// when the name already ends in that same extension, producing "name.pdf.pdf".
    /// Handing over the name WITHOUT its extension lets Finder append it exactly once.
    static func file(_ url: URL, suggestedName: String? = nil) -> NSItemProvider {
        let provider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
        let name = suggestedName ?? url.lastPathComponent
        let nameWithoutExtension = (name as NSString).deletingPathExtension
        provider.suggestedName = nameWithoutExtension.isEmpty ? name : nameWithoutExtension
        return provider
    }

    static func text(_ string: String) -> NSItemProvider {
        NSItemProvider(object: string as NSString)
    }
}
