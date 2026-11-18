import SwiftUI
import SwiftData

@main
struct Villaverde_projectApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [GroceryList.self, GroceryItem.self])
    }
}
