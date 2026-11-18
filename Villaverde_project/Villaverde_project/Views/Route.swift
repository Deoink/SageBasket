
import Foundation

enum Route: Hashable {
    case home(GroceryList)
    case itemDetail(GroceryItem)
    case addEditItem(list: GroceryList, item: GroceryItem?)
    case summary(GroceryList)
    case insights(GroceryList)
    case settings
}
