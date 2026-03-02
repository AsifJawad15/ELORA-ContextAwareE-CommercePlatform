import SwiftUI

struct PaymentFormView: View {
    @Binding var paymentMethod: String
    @Binding var cardLastFour: String
    @Binding var couponCode: String
    var appliedCoupon: Coupon?
    var onApplyCoupon: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Payment Method
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("PAYMENT METHOD")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)

                paymentOption(
                    icon: "creditcard",
                    title: "Credit / Debit Card",
                    value: "card"
                )

                paymentOption(
                    icon: "banknote",
                    title: "Cash on Delivery",
                    value: "cod"
                )
            }

            // Card Details (if card selected)
            if paymentMethod == "card" {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("CARD DETAILS")
                        .font(AppFonts.caption)
                        .tracking(1.2)
                        .foregroundColor(AppColors.muted)

                    EloraTextField(
                        icon: "creditcard",
                        placeholder: "Card Number (last 4 digits)",
                        text: $cardLastFour,
                        keyboardType: .numberPad
                    )

                    Text("This is a demo — no real payment is processed")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                        .italic()
                }
            }

            // Coupon Code
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("COUPON CODE")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)

                HStack(spacing: 8) {
                    EloraTextField(
                        icon: "tag",
                        placeholder: "Enter code",
                        text: $couponCode
                    )

                    Button(action: onApplyCoupon) {
                        Text("APPLY")
                    }
                    .buttonStyle(EloraOutlineButton())
                }

                if let coupon = appliedCoupon {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)

                        Text("Coupon '\(coupon.code)' applied!")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.success)
                    }
                }
            }
        }
    }

    // MARK: - Payment Option

    private func paymentOption(icon: String, title: String, value: String) -> some View {
        Button(action: { paymentMethod = value }) {
            HStack(spacing: 12) {
                Image(systemName: paymentMethod == value ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(paymentMethod == value ? AppColors.accent : AppColors.muted)
                    .font(.system(size: 20))

                Image(systemName: icon)
                    .foregroundColor(AppColors.text)
                    .frame(width: 24)

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)

                Spacer()
            }
            .padding(14)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(
                        paymentMethod == value ? AppColors.accent : AppColors.line,
                        lineWidth: 1
                    )
            )
        }
    }
}
