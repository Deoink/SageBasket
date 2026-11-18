import SwiftUI

/// Screen — shown once, right after Splash. Collects the user's name for a
/// personal touch (no account/login needed since this is an offline app).
struct WelcomeView: View {
    let onContinue: (String) -> Void

    @State private var name: String = ""
    @FocusState private var fieldFocused: Bool

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.categoryBackgrounds[.produce] ?? AppColors.chipBackground)
                        .frame(width: 96, height: 96)
                    Image(systemName: "basket.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primaryAccent)
                }

                VStack(spacing: 8) {
                    Text("What should we call you?")
                        .font(.custom("Georgia", size: 22).weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Just for a personal touch — no account needed.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                TextField("Your name", text: $name)
                    .focused($fieldFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.fieldBorder, lineWidth: 1))
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                Spacer()
                Spacer()

                Button {
                    onContinue(name.trimmingCharacters(in: .whitespaces))
                } label: {
                    Text("Continue")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(canContinue ? AppColors.primaryAccent : AppColors.boughtMuted))
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear { fieldFocused = true }
    }
}

#Preview {
    WelcomeView(onContinue: { _ in })
}
