import Foundation
import SwiftData

@Model
final class OutfitHistory {
    // @Attribute(.unique) is incompatible with CloudKit — uniqueness is managed via CKRecord.ID.
    var id: UUID = UUID()
    var date: Date = Date.now
    var clothingItemIds: [UUID] = []
    var context: String = ""
    var weatherContext: String = ""

    init(id: UUID = UUID(),
         date: Date = Date(),
         clothingItemIds: [UUID] = [],
         context: String = "",
         weatherContext: String = "") {
        self.id = id
        self.date = date
        self.clothingItemIds = clothingItemIds
        self.context = context
        self.weatherContext = weatherContext
    }
}
