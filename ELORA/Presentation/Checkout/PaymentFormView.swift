import SwiftUI

struct PaymentFormView: View {
    @Binding var paymentMethod: String
    @Binding var couponCode: String
    let paymentMethods: [MockPaymentGateway.PaymentMethodDefinition]
    let claimedCoupons: [Coupon]
    var appliedCoupon: Coupon?
    var isPaymentAuthorized: Bool
    var paymentStatusMessage: String?
    var onSelectCoupon: (Coupon) -> Void
    var onApplyCoupon: () -> Void

    private let paymentGrid = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            paymentMethodSection
            couponSection
            paymentStatusSection
        }
    }

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("PAYMENT METHOD")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            LazyVGrid(columns: paymentGrid, spacing: AppSpacing.md) {
                ForEach(paymentMethods, id: \.id) { method in
                    paymentOption(method)
                }
            }

            Text("Tap CONTINUE to open the secure mock gateway for \(CheckoutViewModel.paymentMethodTitle(for: paymentMethod)).")
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
        }
    }

    private var couponSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("COUPONS & DEALS")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            if claimedCoupons.isEmpty {
                Text("Grab coupons from Notifications and they will appear here for one-tap apply.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(claimedCoupons) { coupon in
                            claimedCouponCard(coupon)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack(spacing: 8) {
                EloraTextField(
                    icon: "tag",
                    placeholder: "Enter coupon code",
                    text: $couponCode
                )

                Button(action: onApplyCoupon) {
                    Text("APPLY")
                }
                .buttonStyle(EloraOutlineButton())
            }

            if let coupon = appliedCoupon {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)

                    Text("Coupon '\(coupon.code)' is active for this order.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.success)
                }
            }
        }
    }

    @ViewBuilder
    private var paymentStatusSection: some View {
        if isPaymentAuthorized {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(AppColors.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Authorized")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)

                    Text(paymentStatusMessage ?? "Your mock payment is complete and ready for admin confirmation.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.success.opacity(0.08))
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.success.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func paymentOption(_ method: MockPaymentGateway.PaymentMethodDefinition) -> some View {
        Button(action: { paymentMethod = method.id }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: method.iconSystemName)
                        .font(.system(size: 18))
                        .foregroundColor(paymentMethod == method.id ? .white : AppColors.accent)

                    Spacer()

                    Image(systemName: paymentMethod == method.id ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(paymentMethod == method.id ? .white : AppColors.muted)
                }

                Text(method.title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(paymentMethod == method.id ? .white : AppColors.text)

                Text(method.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(paymentMethod == method.id ? .white.opacity(0.8) : AppColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(paymentMethod == method.id ? AppColors.accent : AppColors.surface)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(paymentMethod == method.id ? AppColors.accent : AppColors.line, lineWidth: 1)
            )
        }
    }

    private func claimedCouponCard(_ coupon: Coupon) -> some View {
        Button(action: { onSelectCoupon(coupon) }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(coupon.code)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)

                    Spacer()

                    Image(systemName: appliedCoupon?.code.uppercased() == coupon.code.uppercased()
                          ? "checkmark.circle.fill"
                          : "ticket.fill")
                        .foregroundColor(appliedCoupon?.code.uppercased() == coupon.code.uppercased()
                                         ? AppColors.success
                                         : AppColors.accent)
                }

                Text(couponSummary(coupon))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)

                if let minimum = coupon.minOrderAmount, minimum > 0 {
                    Text("Min order \(Int(minimum))")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }
            }
            .padding(14)
            .frame(width: 210, height: 120, alignment: .topLeading)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(
                        appliedCoupon?.code.uppercased() == coupon.code.uppercased()
                        ? AppColors.accent
                        : AppColors.line,
                        lineWidth: 1
                    )
            )
        }
    }

    private func couponSummary(_ coupon: Coupon) -> String {
        switch coupon.discountType {
        case .percentage:
            return "\(Int(coupon.discountValue))% off on this checkout"
        case .fixed:
            return "\(Int(coupon.discountValue)) off on this checkout"
        }
    }
}
