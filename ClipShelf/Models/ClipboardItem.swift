import Foundation

enum ClipboardItemKind: String, Codable {
    case text
    case image
    case fileURLs
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var kind: ClipboardItemKind
    var text: String?
    var imageFileName: String?
    var fileURLs: [URL]?
    var sourceAppName: String?
    var sourceAppBundleID: String?
    var pinned: Bool = false

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        kind: ClipboardItemKind,
        text: String? = nil,
        imageFileName: String? = nil,
        fileURLs: [URL]? = nil,
        sourceAppName: String? = nil,
        sourceAppBundleID: String? = nil,
        pinned: Bool = false
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.text = text
        self.imageFileName = imageFileName
        self.fileURLs = fileURLs
        self.sourceAppName = sourceAppName
        self.sourceAppBundleID = sourceAppBundleID
        self.pinned = pinned
    }

    /// Equality ignoring id/date/pinned — used to detect "same content copied again".
    func hasSameContent(as other: ClipboardItem) -> Bool {
        kind == other.kind && text == other.text && imageFileName == other.imageFileName && fileURLs == other.fileURLs
    }

    var previewTitle: String {
        switch kind {
        case .text:
            return text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        case .image:
            return "Bild"
        case .fileURLs:
            let names = (fileURLs ?? []).map { $0.lastPathComponent }
            return names.joined(separator: ", ")
        }
    }
}
