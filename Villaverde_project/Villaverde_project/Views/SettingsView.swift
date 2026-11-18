
import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedCurrency") private var currency = "PHP"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    settingsSection("PREFERENCES") {
                        VStack(spacing: 0) {
                            HStack {
                                Label("Currency", systemImage: "dollarsign.circle")
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                Picker("Currency", selection: $currency) {
                                    Text("PHP (₱)").tag("PHP")
                                    Text("USD ($)").tag("USD")
                                    Text("EUR (€)").tag("EUR")
                                }
                                .tint(AppColors.primaryAccent)
                            }
                            .padding(16)

                            Divider().padding(.horizontal, 16)

                            Toggle(isOn: $notificationsEnabled) {
                                Label("Notifications", systemImage: "bell")
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .tint(AppColors.secondaryAccent)
                            .padding(16)
                        }
                    }

                    settingsSection("ABOUT") {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Grocery List App", systemImage: "basket.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Plan your groceries, organize your shopping lists, and track your spending in one place.")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textMuted)

                            Divider()

                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textMuted)
                        }
                        .padding(16)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textMuted)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppColors.cardBackground)
                )
        }
    }
}
