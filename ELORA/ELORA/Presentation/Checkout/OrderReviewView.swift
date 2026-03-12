import SwiftUI

struct OrderReviewView: View {
    let items: [CartItem]
    let address: Address
    let paymentMethod: String
    let subtotal: Double
    let shipping: Double
    let discount: Double
    let total: Double
    let currencyService: CurrencyService

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Items Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("ORDER ITEMS")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)

                ForEach(items) { item in
                    HStack {
                        Text("\(item.productName) × \(item.quantity)")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.text)
                            .lineLimit(1)
                        Spacer()
                        Text(currencyService.formatted(item.subtotal))
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.text)
                    }
                }
            }

            Divider().background(AppColors.line)

            // Shipping Address
            VStack(alignment: .leading, spacing: 6) {
                Text("SHIP TO")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)

                Text(address.fullName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)

                Text(address.formatted)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(address.phone)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Divider().background(AppColors.line)

            // Payment Method
            HStack {
                Text("PAYMENT")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)
                Spacer()
                Text(paymentMethod == "card" ? "Credit Card" : "Cash on Delivery")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
            }

            Divider().background(AppColors.line)

            // Price Breakdown
            VStack(spacing: 8) {
                priceRow("Subtotal", value: subtotal)

                if shipping > 0 {
                    priceRow("Shipping", value: shipping)
                } else {
                    HStack {
                        Text("Shipping")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("FREE")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.success)
                    }
                }

                if discount > 0 {
                    HStack {
                        Text("Discount")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.success)
                        Spacer()
                        Text("-\(currencyService.formatted(discount))")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.success)
                    }
                }

                Divider().background(AppColors.line)

                HStack {
                    Text("TOTAL")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Text(currencyService.formatted(total))
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
    }

    private func priceRow(_ label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(currencyService.formatted(value))
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
        }
    }
}
