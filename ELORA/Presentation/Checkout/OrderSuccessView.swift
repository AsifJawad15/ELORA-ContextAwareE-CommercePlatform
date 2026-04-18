import SwiftUI

struct OrderSuccessView: View {
    let orderId: String
    let total: String
    var paymentMethod: String? = nil
    var paymentMessage: String? = nil
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

                    Text("Payment successful and waiting for admin confirmation")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                }

                DiamondDivider(color: AppColors.accent)
                    .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    infoRow("Order ID", value: String(orderId.prefix(12)))
                    infoRow("Total", value: total)
                    if let paymentMethod, !paymentMethod.isEmpty {
                        infoRow("Payment", value: paymentMethod)
                    }
                    infoRow("Status", value: "Pending Admin Review")
                }
                .padding(.horizontal, AppSpacing.xl)

                Text(paymentMessage ?? "You will receive notifications as the admin confirms, packs, ships, and delivers your order.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)

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
