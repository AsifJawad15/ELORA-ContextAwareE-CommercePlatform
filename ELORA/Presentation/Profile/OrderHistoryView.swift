import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var currencyService: CurrencyService
    let userId: String
    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(
                    title: "ORDERS",
                    showBack: true,
                    onBack: onBack
                )

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.orders.isEmpty {
                    EmptyStateView(
                        icon: "bag",
                        title: "No Orders Yet",
                        subtitle: "Your order history will appear here"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.orders) { order in
                                OrderCard(order: order, currencyService: currencyService)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await viewModel.loadOrders(userId: userId)
        }
    }
}

// MARK: - Order Card

struct OrderCard: View {
    let order: Order
    let currencyService: CurrencyService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: order.status.icon)
                    .foregroundColor(statusColor)

                Text(order.status.displayName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(statusColor)

                Spacer()

                if let id = order.id {
                    Text("#\(String(id.prefix(8)))")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }
            }

            Divider().background(AppColors.line)

            // Items
            ForEach(order.items) { item in
                HStack {
                    Text("\(item.productName) × \(item.quantity)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                }
            }

            Divider().background(AppColors.line)

            // Footer
            HStack {
                Text("\(order.totalItems) items")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
                Spacer()
                Text(currencyService.formatted(order.total))
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }

    private var statusColor: Color {
        switch order.status {
        case .pending: return AppColors.warning
        case .confirmed: return AppColors.accent
        case .shipped: return .blue
        case .delivered: return AppColors.success
        case .cancelled: return AppColors.error
        }
    }
}
