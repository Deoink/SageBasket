
import SwiftUI

struct HomeView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "PHP"

    let list: GroceryList
    @ObservedObject var controller: ListsController
    @Binding var path: NavigationPath

    @State private var searchText = ""
    @State private var sortOption: SortOption = .recentlyAdded
    @State private var activeFilter: GroceryCategory? = nil
    @State private var showSortSheet = false
    @State private var showClearConfirm = false

    private var visibleItems: [GroceryItem] {
        let filtered = controller.filteredItems(
            in: list,
            search: searchText,
            category: activeFilter
        )
        return controller.sorted(filtered, by: sortOption)
    }

    private var activeItems: [GroceryItem] {
        visibleItems.filter { !$0.bought }
    }

    private var boughtItems: [GroceryItem] {
        visibleItems.filter { $0.bought }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                estimatedTotalCard
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                filterChips
                    .padding(.top, 14)

                if activeItems.isEmpty && boughtItems.isEmpty {
                    ScrollView {
                        emptyState
                    }
                } else {
                    listContent
                }
            }

            fab
        }
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        showSortSheet = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(AppColors.primaryAccent)
                    }

                    Button {
                        path.append(Route.insights(list))
                    } label: {
                        Image(systemName: "chart.bar")
                            .foregroundColor(AppColors.primaryAccent)
                    }

                    Button {
                        path.append(Route.summary(list))
                    } label: {
                        Image(systemName: "chart.pie")
                            .foregroundColor(AppColors.primaryAccent)
                    }
                }
            }
        }
        .confirmationDialog(
            "Remove all checked items?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                controller.deleteAllBought(in: list)
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showSortSheet) {
            sortSheet
                .presentationDetents([.height(300)])
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textMuted)
                .font(.system(size: 14))

            TextField("Search items", text: $searchText)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(AppColors.cardBackground))
        .overlay(
            Capsule().stroke(AppColors.fieldBorder, lineWidth: 1)
        )
    }

    // MARK: - Sort

    private var sortSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "DDD7CF"))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text("Sort by")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, 12)

            ForEach(SortOption.allCases) { option in
                Button {
                    sortOption = option
                    showSortSheet = false
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Circle()
                            .strokeBorder(
                                sortOption == option
                                    ? AppColors.secondaryAccent
                                    : AppColors.boughtMuted,
                                lineWidth: 2
                            )
                            .background(
                                Circle().fill(
                                    sortOption == option
                                        ? AppColors.secondaryAccent
                                        : Color.clear
                                )
                            )
                            .frame(width: 18, height: 18)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                }
            }

            Spacer()
        }
        .background(AppColors.cardBackground)
    }

    // MARK: - Estimated Total

    private var estimatedTotalCard: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "basket")
                        .foregroundColor(AppColors.primaryAccent)
                        .font(.system(size: 13))

                    Text("Estimated Total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                }

                Spacer()

                Text(CurrencyFormatter.format(controller.totalAll(for: list)))
                    .font(.custom("Georgia", size: 16).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            ProgressView(value: controller.progress(for: list))
                .progressViewStyle(.linear)
                .tint(AppColors.primaryAccent)
                .background(AppColors.chipBackground)
                .clipShape(Capsule())

            HStack {
                Text("\(CurrencyFormatter.format(controller.totalBought(for: list))) spent")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.boughtMuted)

                Spacer()

                Text("\(CurrencyFormatter.format(controller.totalRemaining(for: list))) remaining")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.secondaryAccent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.chipBackground, lineWidth: 1)
        )
        .shadow(
            color: AppColors.textPrimary.opacity(0.07),
            radius: 12,
            x: 0,
            y: 2
        )
    }

    // MARK: - Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    title: "All",
                    isSelected: activeFilter == nil
                ) {
                    activeFilter = nil
                }

                ForEach(GroceryCategory.allCases) { category in
                    filterChip(
                        title: category.rawValue,
                        isSelected: activeFilter == category
                    ) {
                        activeFilter = category
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func filterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        isSelected
                            ? AppColors.secondaryAccent
                            : AppColors.chipBackground
                    )
                )
                .foregroundColor(
                    isSelected ? .white : Color(hex: "7A736C")
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - List

    private var listContent: some View {
        List {
            if sortOption == .recentlyAdded {
                ForEach(
                    controller.groupedActiveItems(activeItems),
                    id: \.category
                ) { group in
                    Section(
                        header: sectionHeader(
                            title: group.category.rawValue
                        )
                    ) {
                        ForEach(group.items) { item in
                            row(for: item)
                        }
                    }
                }
            } else if !activeItems.isEmpty {
                Section(
                    header: sectionHeader(title: "To buy")
                ) {
                    ForEach(activeItems) { item in
                        row(for: item)
                    }
                }
            }

            if !boughtItems.isEmpty {
                Section(
                    header: sectionHeader(
                        title: "In the basket ✓",
                        muted: true,
                        showClear: true
                    )
                ) {
                    ForEach(boughtItems) { item in
                        row(for: item)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
    }

    private func row(for item: GroceryItem) -> some View {
        NavigationLink(value: Route.itemDetail(item)) {
            GroceryItemRow(
                item: item,
                onToggle: {
                    controller.toggleBought(item)
                }
            )
        }
        .listRowInsets(
            EdgeInsets(
                top: 5,
                leading: 20,
                bottom: 5,
                trailing: 20
            )
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                controller.deleteItem(item)
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .tint(AppColors.deleteAccent)
        }
    }

    private func sectionHeader(
        title: String,
        muted: Bool = false,
        showClear: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(
                        muted
                            ? Color(hex: "EEEBE6")
                            : AppColors.chipBackground
                    )
                )
                .foregroundColor(
                    muted
                        ? AppColors.textMuted
                        : AppColors.textPrimary
                )

            Rectangle()
                .fill(Color(hex: "E8E1D9"))
                .frame(height: 1)

            if showClear {
                Button {
                    showClearConfirm = true
                } label: {
                    Text("Clear")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.deleteAccent)
                }
            }
        }
        .listRowInsets(
            EdgeInsets(
                top: 8,
                leading: 20,
                bottom: 0,
                trailing: 20
            )
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .textCase(nil)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 56))
                .foregroundColor(
                    AppColors.primaryAccent.opacity(0.5)
                )

            Text(
                searchText.isEmpty
                    ? "Nothing here yet —\nadd your first item"
                    : "No items match \"\(searchText)\""
            )
            .multilineTextAlignment(.center)
            .font(.custom("Georgia", size: 16).italic())
            .foregroundColor(AppColors.textMuted)
        }
        .padding(.top, 100)
    }

    // MARK: - Add Button

    private var fab: some View {
        Button {
            path.append(
                Route.addEditItem(list: list, item: nil)
            )
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(AppColors.primaryAccent)
                )
                .shadow(
                    color: AppColors.primaryAccent.opacity(0.38),
                    radius: 14,
                    x: 0,
                    y: 4
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }
}
