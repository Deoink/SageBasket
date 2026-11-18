import Foundation
import SwiftData

/// MODEL — one named grocery list (e.g. "This Week's Groceries"), stored in the
/// SwiftData database. Deleting a list also deletes its items (cascade).
@Model
final class GroceryList {
    var name: String
    var dateCreated: Date

    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.list)
    var items: [GroceryItem] = []

    init(name: String, dateCreated: Date = Date()) {
        self.name = name
        self.dateCreated = dateCreated
    }
}
