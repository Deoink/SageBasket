import Foundation
import SwiftData

enum GroceryCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case produce = "Produce"
    case dairy = "Dairy"
    case pantry = "Pantry"
    case meat = "Meat"
    case other = "Other"

    var id: String { rawValue }
}

/// How a list of items can be ordered on the Home screen.
enum SortOption: String, CaseIterable, Identifiable {
    case nameAZ = "Name (A-Z)"
    case priceLowHigh = "Price (low to high)"
    case priceHighLow = "Price (high to low)"
    case recentlyAdded = "Recently added"

    var id: String { rawValue }
}

/// MODEL — one grocery item, stored in the SwiftData database.

@Model
final class GroceryItem {
    var name: String
    var quantity: Int
    var price: Double
    var category: GroceryCategory
    var bought: Bool

    var dateAdded: Date

    // Actual date and time when marked as bought
    var dateBought: Date?

    var list: GroceryList?

    init(
        name: String,
        quantity: Int = 1,
        price: Double = 0,
        category: GroceryCategory = .other,
        bought: Bool = false,
        dateAdded: Date = Date(),
        dateBought: Date? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.bought = bought
        self.dateAdded = dateAdded
        self.dateBought = bought ? (dateBought ?? Date()) : nil
    }

    var lineTotal: Double {
        price * Double(quantity)
    }
}

