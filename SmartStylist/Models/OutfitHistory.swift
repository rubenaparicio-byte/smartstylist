import Foundation
import SwiftData

@Model
final class OutfitHistory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var clothingItemIds: [UUID]
    var context: String
    var weatherContext: String

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
