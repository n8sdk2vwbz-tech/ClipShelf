import Foundation

enum ShelfItemKind: String, Codable {
    case fileURL
    case text
    case image
}

struct ShelfItem: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: ShelfItemKind
    var fileURL: URL?
    var text: String?
    var imageFileName: String?
    var displayName: String
    var addedDate: Date

    init(
        id: UUID = UUID(),
        kind: ShelfItemKind,
        fileURL: URL? = nil,
        text: String? = nil,
        imageFileName: String? = nil,
        displayName: String,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.fileURL = fileURL
        self.text = text
        self.imageFileName = imageFileName
        self.displayName = displayName
        self.addedDate = addedDate
    }
}
