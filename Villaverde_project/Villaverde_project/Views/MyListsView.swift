import SwiftUI
import SwiftData

/// Screen — the app's true home after onboarding. Shows every GroceryList as
/// a card; tapping one pushes into that list's basket (HomeView). Owns the
/// single NavigationStack shared by every pushed screen below it.
struct MyListsView: View {
    @AppStorage("userName") private var userName = ""
    @Environment(\.modelContext) private var modelContext
    @StateObject private var controller = ListsController()
    @State private var path = NavigationPath()
    @State private var showCreateSheet = false
    @State private var newListName = ""
    @State private var renamingList: GroceryList?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    greeting
                    if controller.lists.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        listCards
                    }
                }

                fab
            }
            .navigationBarHidden(true)
            .onAppear { controller.attach(modelContext) }
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
            .sheet(isPresented: $showCreateSheet) {
                createListSheet
                    .presentationDetents([.height(220)])
            }
            .sheet(item: $renamingList) { list in
                renameListSheet(list)
                    .presentationDetents([.height(220)])
            }
        }
    }

    // MARK: - Greeting

    
    private var greeting: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(userName.isEmpty ? "My Lists" : "Hi, \(userName) 👋")
                    .font(.custom("Georgia", size: 26).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Your grocery lists")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)
            }

            Spacer()

            Button {
                path.append(Route.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19))
                    .foregroundColor(AppColors.primaryAccent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(AppColors.cardBackground)
                    )
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }


    // MARK: - List cards

    private var listCards: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(controller.lists) { list in
                    Button {
                        path.append(Route.home(list))
                    } label: {
                        listCard(list)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            renamingList = list
                            renameText = list.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            controller.deleteList(list)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    private func listCard(_ list: GroceryList) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.categoryBackgrounds[.produce] ?? AppColors.chipBackground)
                    .frame(width: 48, height: 48)
                Image(systemName: "basket.fill")
                    .foregroundColor(AppColors.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(list.items.count) item\(list.items.count == 1 ? "" : "s") · ₱\(controller.totalAll(for: list), specifier: "%.0f")")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)

                HStack(spacing: 4) {
                    ForEach(Array(Set(list.items.map { $0.category })).prefix(4), id: \.self) { category in
                        Circle()
                            .fill(AppColors.categoryColors[category] ?? AppColors.textMuted)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.boughtMuted)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(AppColors.cardBackground))
        .shadow(color: AppColors.textPrimary.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "basket")
                .font(.system(size: 56))
                .foregroundColor(AppColors.primaryAccent.opacity(0.5))
            Text("No lists yet —\ncreate your first one")
                .multilineTextAlignment(.center)
                .font(.custom("Georgia", size: 16).italic())
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - FAB

    private var fab: some View {
        Button {
            newListName = ""
            showCreateSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppColors.primaryAccent))
                .shadow(color: AppColors.primaryAccent.opacity(0.38), radius: 14, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    // MARK: - Create / Rename sheets

    private var createListSheet: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color(hex: "DDD7CF")).frame(width: 40, height: 4).padding(.top, 10)
            Text("New list")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            TextField("List name", text: $newListName)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.background))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.fieldBorder, lineWidth: 1))
                .padding(.horizontal, 24)

            Button {
                let trimmed = newListName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                controller.createList(name: trimmed)
                showCreateSheet = false
            } label: {
                Text("Create")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(AppColors.primaryAccent))
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(AppColors.cardBackground)
    }

    private func renameListSheet(_ list: GroceryList) -> some View {
        VStack(spacing: 16) {
            Capsule().fill(Color(hex: "DDD7CF")).frame(width: 40, height: 4).padding(.top, 10)
            Text("Rename list")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            TextField("List name", text: $renameText)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.background))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.fieldBorder, lineWidth: 1))
                .padding(.horizontal, 24)

            Button {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                controller.renameList(list, to: trimmed)
                renamingList = nil
            } label: {
                Text("Save")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(AppColors.primaryAccent))
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(AppColors.cardBackground)
    }

    // MARK: - Route destinations

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home(let list):
            HomeView(list: list, controller: controller, path: $path)
        case .itemDetail(let item):
            ItemDetailView(item: item, controller: controller, path: $path)
        case .addEditItem(let list, let item):
            AddEditItemView(list: list, editingItem: item, controller: controller, path: $path)
        case .summary(let list):
            SummaryView(list: list, controller: controller)
        case .insights(let list):
            SpendingInsightsView(list: list, controller: controller)
            SpendingInsightsView(list: list, controller: controller)
        case .settings:
            SettingsView()

        }
    }
}

#Preview {
    MyListsView()
}
