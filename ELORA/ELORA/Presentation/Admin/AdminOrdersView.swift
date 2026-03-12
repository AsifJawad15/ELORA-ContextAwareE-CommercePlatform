import SwiftUI

struct AdminOrdersView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var filterStatus: OrderStatus?

    private var filteredOrders: [Order] {
        guard let status = filterStatus else { return viewModel.orders }
        return viewModel.orders.filter { $0.status == status }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    ForEach(OrderStatus.allCases, id: \.rawValue) { status in
                        filterChip(
                            label: status.displayName,
                            isSelected: filterStatus == status
                        ) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
            }

            // Stats
            HStack(spacing: 12) {
                orderStat("Total", "\(viewModel.orders.count)", AppColors.accent)
                orderStat("Pending", "\(viewModel.orders.filter { $0.status == .pending }.count)", AppColors.warning)
                orderStat("Shipped", "\(viewModel.orders.filter { $0.status == .shipped }.count)", .blue)
                orderStat("Delivered", "\(viewModel.orders.filter { $0.status == .delivered }.count)", AppColors.success)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)

            if viewModel.isLoading {
                LoadingView()
            } else if filteredOrders.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Orders",
                    subtitle: "No orders match the current filter"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredOrders) { order in
                            AdminOrderCard(
                                order: order,
                                onUpdateStatus: { newStatus in
                                    if let id = order.id {
                                        Task {
                                            await viewModel.updateOrderStatus(
                                                orderId: id, status: newStatus
                                            )
                                        }
                                    }
                                },
                                onDelete: {
                                    if let id = order.id {
                                        Task { await viewModel.deleteOrder(orderId: id) }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? .white : AppColors.text)
                .background(isSelected ? AppColors.accent : AppColors.surface)
                .cornerRadius(AppRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(isSelected ? AppColors.accent : AppColors.line, lineWidth: 1)
                )
        }
    }

    private func orderStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.sm)
    }
}

// MARK: - Admin Order Card

struct AdminOrderCard: View {
    let order: Order
    var onUpdateStatus: (OrderStatus) -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            // User & Date
            HStack {
                Text("User: \(String(order.userId.prefix(12)))...")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.muted)
                Spacer()
                if let date = order.createdAt {
                    Text(date, style: .date)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }
            }

            Divider().background(AppColors.line)

            // Items
            ForEach(order.items) { item in
                HStack {
                    Text("\(item.productName) x\(item.quantity)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.text)
                }
            }

            Divider().background(AppColors.line)

            // Total + Address
            HStack {
                Text("\(order.totalItems) items")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
                Spacer()
                Text("$\(order.total, specifier: "%.2f")")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.accent)
            }

            Text("Ship to: \(order.shippingAddress.formatted)")
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
                .lineLimit(1)

            Divider().background(AppColors.line)

            // Actions
            HStack(spacing: 8) {
                Text("Update:")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.muted)

                ForEach(OrderStatus.allCases, id: \.rawValue) { status in
                    if status != order.status {
                        Button(action: { onUpdateStatus(status) }) {
                            Text(status.displayName)
                                .font(AppFonts.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.card)
                                .foregroundColor(AppColors.text)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.error)
                }
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
