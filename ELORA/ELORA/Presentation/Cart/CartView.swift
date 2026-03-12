import SwiftUI

struct CartView: View {
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var currencyService: CurrencyService
    var onCheckout: () -> Void
    var onContinueShopping: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                EloraTopBar(title: "MY CART")

                if cartVM.isLoading {
                    LoadingView()
                } else if cartVM.items.isEmpty {
                    EmptyStateView(
                        icon: "bag",
                        title: "Your Cart is Empty",
                        subtitle: "Explore our collection and find something you love",
                        actionTitle: "BROWSE PRODUCTS",
                        action: onContinueShopping
                    )
                } else {
                    // Cart Items
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(cartVM.items) { item in
                                CartItemRow(
                                    item: item,
                                    currencyService: currencyService,
                                    onUpdateQuantity: { qty in
                                        Task {
                                            await cartVM.updateQuantity(
                                                itemId: item.id ?? "",
                                                quantity: qty
                                            )
                                        }
                                    },
                                    onRemove: {
                                        Task {
                                            await cartVM.removeItem(itemId: item.id ?? "")
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, 180)
                    }

                    Spacer()
                }
            }

            // Bottom Summary
            if !cartVM.items.isEmpty {
                VStack {
                    Spacer()
                    cartSummary
                }
            }
        }
    }

    // MARK: - Cart Summary

    private var cartSummary: some View {
        VStack(spacing: 12) {
            Divider().background(AppColors.line)

            HStack {
                Text("Subtotal (\(cartVM.itemCount) items)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.muted)
                Spacer()
                Text(currencyService.formatted(cartVM.subtotal))
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
            }

            Button(action: onCheckout) {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("PROCEED TO CHECKOUT")
                }
            }
            .buttonStyle(EloraPrimaryButton())
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            AppColors.background
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: CartItem
    let currencyService: CurrencyService
    var onUpdateQuantity: (Int) -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Image
            AsyncImage(url: URL(string: item.productImageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    AppColors.surface
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(AppColors.muted)
                        )
                @unknown default:
                    AppColors.surface
                }
            }
            .frame(width: 80, height: 100)
            .clipped()
            .cornerRadius(AppRadius.sm)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let size = item.size {
                        Text("Size: \(size)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.muted)
                    }
                    if let color = item.color {
                        Text("Color: \(color)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.muted)
                    }
                }

                Text(currencyService.formatted(item.price))
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.accent)

                Spacer()

                // Quantity controls
                HStack(spacing: 12) {
                    Button(action: { onUpdateQuantity(item.quantity - 1) }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(AppColors.muted)
                    }

                    Text("\(item.quantity)")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)
                        .frame(width: 20)

                    Button(action: { onUpdateQuantity(item.quantity + 1) }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(AppColors.accent)
                    }

                    Spacer()

                    // Subtotal
                    Text(currencyService.formatted(item.subtotal))
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)
                }
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.error.opacity(0.8))
            }
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}
