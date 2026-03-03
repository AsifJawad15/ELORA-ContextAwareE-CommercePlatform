import SwiftUI

struct OrderSuccessView: View {
    let orderId: String
    let total: String
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Success Icon
                ZStack {
                    Circle()
                        .fill(AppColors.success.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.success)
                }

                VStack(spacing: 8) {
                    Text("ORDER PLACED!")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.text)

                    Text("Thank you for shopping with ELORA")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.muted)
                }

                DiamondDivider(color: AppColors.accent)
                    .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    infoRow("Order ID", value: String(orderId.prefix(12)))
                    infoRow("Total", value: total)
                    infoRow("Status", value: "Confirmed")
                }
                .padding(.horizontal, AppSpacing.xl)

                Text("You will receive a confirmation soon.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)

                Spacer()

                Button(action: onContinue) {
                    Text("CONTINUE SHOPPING")
                }
                .buttonStyle(EloraPrimaryButton())
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
            Spacer()
            Text(value)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
        }
    }
}
