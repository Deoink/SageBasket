import SwiftUI

/// Screen — Daily / Weekly / Monthly spending breakdown for a single list.
/// Reached from Home's toolbar chart icon.
struct SpendingInsightsView: View {
    let list: GroceryList
    @ObservedObject var controller: ListsController

    private enum Period: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    @State private var period: Period = .daily
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    segmentedControl

                    switch period {
                    case .daily: dailyView
                    case .weekly: weeklyView
                    case .monthly: monthlyView
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Spending Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 6) {
            ForEach(Period.allCases, id: \.self) { p in
                Button {
                    period = p
                } label: {
                    Text(p.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(period == p ? AppColors.secondaryAccent : AppColors.chipBackground))
                        .foregroundColor(period == p ? .white : AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Daily

    private var dailyView: some View {
        let daily = controller.dailyTotals(for: list)
        let maxTotal = max(daily.map { $0.total }.max() ?? 0, 1)
        let dayItems = controller.items(for: list, on: selectedDay)
        let dayTotal = dayItems.reduce(0) { $0 + $1.lineTotal }

        return VStack(alignment: .leading, spacing: 16) {
            barChart(
                values: daily.map { ($0.date, $0.total) },
                maxValue: maxTotal,
                labelFormat: "E",
                color: AppColors.primaryAccent,
                onSelect: { selectedDay = Calendar.current.startOfDay(for: $0) },
                selected: selectedDay
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(dayItems.isEmpty ? "No purchases yet for this day" : "Purchased that day")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)

                if dayItems.isEmpty {
                    emptyState
                } else {
                    ForEach(dayItems) { item in
                        itemRow(item)
                    }
                }
            }

            totalCard(label: "Total for selected day", value: dayTotal)
        }
    }

    // MARK: - Weekly

    private var weeklyView: some View {
        let weekly = controller.weeklyTotals(for: list)
        let maxTotal = max(weekly.map { $0.total }.max() ?? 0, 1)
        let monthTotal = weekly.reduce(0) { $0 + $1.total }

        return VStack(alignment: .leading, spacing: 16) {
            totalCard(label: "This period so far", value: monthTotal)

            barChart(
                values: weekly.map { ($0.weekStart, $0.total) },
                maxValue: maxTotal,
                labelFormat: "MMM d",
                color: AppColors.secondaryAccent,
                onSelect: { _ in },
                selected: nil
            )

            VStack(spacing: 10) {
                ForEach(Array(weekly.enumerated()), id: \.offset) { _, week in
                    weekRow(start: week.weekStart, total: week.total)
                }
            }
        }
    }

    // MARK: - Monthly

    private var monthlyView: some View {
        let monthly = controller.monthlyTotals(for: list)
        let maxTotal = max(monthly.map { $0.total }.max() ?? 0, 1)
        let yearTotal = monthly.reduce(0) { $0 + $1.total }

        return VStack(alignment: .leading, spacing: 16) {
            totalCard(label: "This year so far", value: yearTotal)

            barChart(
                values: monthly.map { ($0.monthStart, $0.total) },
                maxValue: maxTotal,
                labelFormat: "MMM",
                color: AppColors.primaryAccent,
                onSelect: { _ in },
                selected: nil
            )

            VStack(spacing: 10) {
                ForEach(Array(monthly.enumerated()), id: \.offset) { index, month in
                    let previous = index > 0 ? monthly[index - 1].total : nil
                    monthRow(start: month.monthStart, total: month.total, previous: previous)
                }
            }
        }
    }

    // MARK: - Shared pieces

    private func barChart(
        values: [(Date, Double)],
        maxValue: Double,
        labelFormat: String,
        color: Color,
        onSelect: @escaping (Date) -> Void,
        selected: Date?
    ) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, entry in
                let (date, total) = entry
                let isSelected = selected.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isSelected ? AppColors.secondaryAccent : color)
                        .frame(height: max(6, CGFloat(total / maxValue) * 90))
                    Text(dateLabel(date, format: labelFormat))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture { onSelect(date) }
            }
        }
        .frame(height: 120, alignment: .bottom)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(AppColors.cardBackground))
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        HStack {
            Circle()
                .fill(AppColors.categoryColors[item.category] ?? AppColors.textMuted)
                .frame(width: 8, height: 8)
            Text(item.name)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text("₱\(item.lineTotal, specifier: "%.0f")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
    }

    private func weekRow(start: Date, total: Double) -> some View {
        HStack {
            Text("Week of \(dateLabel(start, format: "MMM d"))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text("₱\(total, specifier: "%.0f")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.secondaryAccent)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.cardBackground))
    }

    private func monthRow(start: Date, total: Double, previous: Double?) -> some View {
        let trendUp = previous.map { total > $0 } ?? false
        let trendDown = previous.map { total < $0 } ?? false
        return HStack {
            Text(dateLabel(start, format: "MMMM yyyy"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if trendUp {
                Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundColor(AppColors.deleteAccent)
            } else if trendDown {
                Image(systemName: "arrow.down.right").font(.system(size: 10)).foregroundColor(AppColors.secondaryAccent)
            }
            Text("₱\(total, specifier: "%.0f")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.cardBackground))
    }

    private func totalCard(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textMuted)
            Spacer()
            Text("₱\(value, specifier: "%.0f")")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.cardBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 40))
                .foregroundColor(AppColors.primaryAccent.opacity(0.5))
            Text("No purchases yet for this period")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func dateLabel(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
