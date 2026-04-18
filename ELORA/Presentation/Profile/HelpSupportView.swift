import SwiftUI

struct HelpSupportView: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(
                    title: "HELP & SUPPORT",
                    showBack: true,
                    onBack: onBack
                )

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        supportHero

                        supportCard(
                            icon: "shippingbox",
                            title: "Orders & Delivery",
                            body: "Track active orders from Order History. Demo delivery updates appear automatically as the project data changes."
                        )

                        supportCard(
                            icon: "arrow.uturn.backward",
                            title: "Returns & Exchanges",
                            body: "For this project build, returns are mock-only. Mark an item for return from the admin side or contact the demo team for approval."
                        )

                        supportCard(
                            icon: "creditcard",
                            title: "Payments",
                            body: "Card payments use the project’s mock payment gateway, so approved and declined responses are simulated for testing."
                        )

                        supportCard(
                            icon: "person.crop.circle.badge.questionmark",
                            title: "Need More Help?",
                            body: "Email: support@elora-demo.app\nPhone: +1 (555) 014-ELORA\nHours: 9:00 AM - 6:00 PM"
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var supportHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("We’re Here To Help")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)

            Text("This support page is a project mock, but it’s designed to feel like a real customer help center with quick guidance for common issues.")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }

    private func supportCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.accent)
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
            }

            Text(body)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }
}
