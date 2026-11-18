import Foundation
import SwiftUI
import SwiftData
import Combine

/// MVC "Controller" layer. Owns every database operation (SwiftData):
/// creating/renaming/deleting lists, adding/updating/deleting items, plus
/// derived values (totals, filtering, sorting, spending insights).
/// Views never touch the database directly — they call this controller.
@MainActor
final class ListsController: ObservableObject {
    @Published private(set) var lists: [GroceryList] = []
    private var context: ModelContext?

    // MARK: - Setup

    /// Called once by MyListsView with the app's SwiftData context.
    func attach(_ context: ModelContext) {
        guard self.context == nil else { return }
        self.context = context
        seedIfNeeded()
        refresh()
    }

    private func refresh() {
        guard let context else { return }
        let descriptor = FetchDescriptor<GroceryList>(sortBy: [SortDescriptor(\.dateCreated)])
        lists = (try? context.fetch(descriptor)) ?? []
    }

    private func save() {
        try? context?.save()
        objectWillChange.send()
    }

    /// Puts sample data in the database on the very first launch only.
    private func seedIfNeeded() {
        let key = "hasSeededSampleData"
        guard let context, !UserDefaults.standard.bool(forKey: key) else { return }

        let calendar = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: -n, to: Date()) ?? Date()
        }
        func monthsAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .month, value: -n, to: Date()) ?? Date()
        }

        let weekly = GroceryList(name: "This Week's Groceries")
        context.insert(weekly)
        let weeklyItems = [
            GroceryItem(name: "Sourdough bread", quantity: 1, price: 120, category: .pantry, bought: false, dateAdded: daysAgo(0)),
            GroceryItem(name: "Heirloom tomatoes", quantity: 4, price: 80, category: .produce, bought: false, dateAdded: daysAgo(0)),
            GroceryItem(name: "Whole milk", quantity: 1, price: 95, category: .dairy, bought: false, dateAdded: daysAgo(1)),
            GroceryItem(name: "Baby spinach", quantity: 1, price: 65, category: .produce, bought: true, dateAdded: daysAgo(1)),
            GroceryItem(name: "Free-range eggs", quantity: 12, price: 180, category: .dairy, bought: true, dateAdded: daysAgo(2)),
            GroceryItem(name: "Olive oil", quantity: 1, price: 220, category: .pantry, bought: true, dateAdded: daysAgo(5)),
            GroceryItem(name: "Chicken thighs", quantity: 4, price: 310, category: .meat, bought: true, dateAdded: daysAgo(8)),
            GroceryItem(name: "Greek yogurt", quantity: 2, price: 140, category: .dairy, bought: true, dateAdded: daysAgo(12)),
            GroceryItem(name: "Rice, 5kg", quantity: 1, price: 260, category: .pantry, bought: true, dateAdded: daysAgo(20)),
            GroceryItem(name: "Ground pork", quantity: 2, price: 190, category: .meat, bought: true, dateAdded: monthsAgo(1)),
            GroceryItem(name: "Dish soap", quantity: 1, price: 55, category: .other, bought: true, dateAdded: monthsAgo(2)),
            GroceryItem(name: "Bananas", quantity: 6, price: 60, category: .produce, bought: true, dateAdded: monthsAgo(3))
        ]
        for item in weeklyItems {
            context.insert(item)
            item.list = weekly
        }

        let party = GroceryList(name: "Party Supplies", dateCreated: Date().addingTimeInterval(1))
        context.insert(party)
        let partyItems = [
            GroceryItem(name: "Paper cups", quantity: 2, price: 45, category: .other, bought: false),
            GroceryItem(name: "Soda, 1.5L", quantity: 4, price: 65, category: .other, bought: false),
            GroceryItem(name: "Chips", quantity: 3, price: 55, category: .pantry, bought: true)
        ]
        for item in partyItems {
            context.insert(item)
            item.list = party
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - List-level CRUD

    func createList(name: String) {
        guard let context else { return }
        context.insert(GroceryList(name: name))
        save()
        refresh()
    }

    func renameList(_ list: GroceryList, to newName: String) {
        list.name = newName
        save()
    }

    func deleteList(_ list: GroceryList) {
        context?.delete(list)
        save()
        refresh()
    }

    // MARK: - Item-level CRUD

    
    func addItem(
        name: String,
        quantity: Int,
        price: Double,
        category: GroceryCategory,
        bought: Bool,
        to list: GroceryList
    ) {
        guard let context else { return }

        let item = GroceryItem(
            name: name,
            quantity: quantity,
            price: price,
            category: category,
            bought: bought,
            dateBought: bought ? Date() : nil
        )

        context.insert(item)
        item.list = list
        save()
    }

    func updateItem(
        _ item: GroceryItem,
        name: String,
        quantity: Int,
        price: Double,
        category: GroceryCategory,
        bought: Bool
    ) {
        item.name = name
        item.quantity = quantity
        item.price = price
        item.category = category

        if item.bought != bought {
            item.dateBought = bought ? Date() : nil
        }

        item.bought = bought
        save()
    }

    func toggleBought(_ item: GroceryItem) {
        item.bought.toggle()
        item.dateBought = item.bought ? Date() : nil
        save()
    }


    // MARK: - Read / derived data (per list)

    func filteredItems(in list: GroceryList, search: String, category: GroceryCategory?) -> [GroceryItem] {
        var result = list.items
        if let category {
            result = result.filter { $0.category == category }
        }
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        return result
    }

    func sorted(_ items: [GroceryItem], by option: SortOption) -> [GroceryItem] {
        switch option {
        case .nameAZ:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .priceLowHigh:
            return items.sorted { $0.price < $1.price }
        case .priceHighLow:
            return items.sorted { $0.price > $1.price }
        case .recentlyAdded:
            return items.sorted { $0.dateAdded > $1.dateAdded }
        }
    }

    func groupedActiveItems(_ items: [GroceryItem]) -> [(category: GroceryCategory, items: [GroceryItem])] {
        let active = items.filter { !$0.bought }
        return GroceryCategory.allCases.compactMap { category in
            let matches = active.filter { $0.category == category }
            return matches.isEmpty ? nil : (category, matches)
        }
    }

    func totalAll(for list: GroceryList) -> Double {
        list.items.reduce(0) { $0 + $1.lineTotal }
    }

    func totalBought(for list: GroceryList) -> Double {
        list.items.filter { $0.bought }.reduce(0) { $0 + $1.lineTotal }
    }

    func totalRemaining(for list: GroceryList) -> Double {
        totalAll(for: list) - totalBought(for: list)
    }

    func progress(for list: GroceryList) -> Double {
        let total = totalAll(for: list)
        return total > 0 ? totalBought(for: list) / total : 0
    }

    func totalsByCategory(for list: GroceryList) -> [(category: GroceryCategory, total: Double)] {
        GroceryCategory.allCases.compactMap { category in
            let total = list.items.filter { $0.category == category }.reduce(0) { $0 + $1.lineTotal }
            return total > 0 ? (category, total) : nil
        }
    }

    // MARK: - Spending Insights (bought items in a list)

    
    // MARK: - Spending Insights

    private func boughtItems(for list: GroceryList) -> [GroceryItem] {
        list.items.filter {
            $0.bought && $0.dateBought != nil
        }
    }

    // DAILY - Last 7 days
    func dailyTotals(for list: GroceryList)
        -> [(date: Date, total: Double)] {

        let calendar = Calendar.current
        let bought = boughtItems(for: list)

        return (0..<7).reversed().map { offset in
            let day = calendar.date(
                byAdding: .day,
                value: -offset,
                to: Date()
            ) ?? Date()

            let total = bought
                .filter {
                    guard let date = $0.dateBought else {
                        return false
                    }
                    return calendar.isDate(date, inSameDayAs: day)
                }
                .reduce(0) { $0 + $1.lineTotal }

            return (day, total)
        }
    }

    // ITEMS PURCHASED ON SELECTED DAY
    func items(for list: GroceryList, on date: Date)
        -> [GroceryItem] {

        let calendar = Calendar.current

        return boughtItems(for: list).filter {
            guard let boughtDate = $0.dateBought else {
                return false
            }
            return calendar.isDate(
                boughtDate,
                inSameDayAs: date
            )
        }
    }

    // WEEKLY - Last 5 calendar weeks
    func weeklyTotals(for list: GroceryList)
        -> [(weekStart: Date, total: Double)] {

        let calendar = Calendar.current
        let bought = boughtItems(for: list)

        let currentWeekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: Date()
        )?.start ?? calendar.startOfDay(for: Date())

        return (0..<5).reversed().map { offset in
            let weekStart = calendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: currentWeekStart
            ) ?? currentWeekStart

            let weekEnd = calendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: weekStart
            ) ?? weekStart

            let total = bought
                .filter {
                    guard let date = $0.dateBought else {
                        return false
                    }
                    return date >= weekStart && date < weekEnd
                }
                .reduce(0) { $0 + $1.lineTotal }

            return (weekStart, total)
        }
    }

    // MONTHLY - Last 6 calendar months
    func monthlyTotals(for list: GroceryList)
        -> [(monthStart: Date, total: Double)] {

        let calendar = Calendar.current
        let bought = boughtItems(for: list)

        let currentMonthStart = calendar.dateInterval(
            of: .month,
            for: Date()
        )?.start ?? calendar.startOfDay(for: Date())

        return (0..<6).reversed().map { offset in
            let monthStart = calendar.date(
                byAdding: .month,
                value: -offset,
                to: currentMonthStart
            ) ?? currentMonthStart

            let monthEnd = calendar.date(
                byAdding: .month,
                value: 1,
                to: monthStart
            ) ?? monthStart

            let total = bought
                .filter {
                    guard let date = $0.dateBought else {
                        return false
                    }
                    return date >= monthStart && date < monthEnd
                }
                .reduce(0) { $0 + $1.lineTotal }

            return (monthStart, total)
        }
    }
    
    
    // MARK: - Delete Grocery Item

    func deleteItem(_ item: GroceryItem) {
        guard let context = context else { return }

        context.delete(item)
        save()
    }

    // MARK: - Delete All Bought Items

    func deleteAllBought(in list: GroceryList) {
        guard let context = context else { return }

        let boughtItems = list.items.filter { $0.bought }

        for item in boughtItems {
            context.delete(item)
        }

        save()
    }
}
