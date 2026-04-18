import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    let userId: String
    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(
                    title: "NOTIFICATIONS",
                    showBack: true,
                    onBack: onBack
                )

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                if !viewModel.notifications.isEmpty {
                    actionBar
                }

                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)
                }

                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell",
                        title: "No Notifications Yet",
                        subtitle: "New coupons, deals, and order updates will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                notificationCard(notification)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await viewModel.load(userId: userId)
        }
    }

    private var actionBar: some View {
        HStack {
            Spacer()
            Button("MARK ALL AS READ") {
                Task { await viewModel.markAllAsRead(userId: userId) }
            }
            .font(AppFonts.caption)
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
        }
    }

    private func notificationCard(_ notification: BuyerNotification) -> some View {
        let coupon = viewModel.coupon(for: notification)
        let couponCode = notification.couponCode?.uppercased()
        let isClaimed = couponCode.map { viewModel.claimedCouponCodes.contains($0) } ?? false

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon(for: notification.type))
                    .foregroundColor(color(for: notification.type))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(notification.title)
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.text)

                        if !notification.isRead {
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.message)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)

                    if let createdAt = notification.createdAt {
                        Text(createdAt, style: .relative)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.muted)
                    }
                }
            }

            if let coupon, let couponCode {
                VStack(alignment: .leading, spacing: 8) {
                    Text(couponSummary(coupon))
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accent)

                    HStack {
                        Text(couponCode)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.card)
                            .cornerRadius(AppRadius.full)

                        Spacer()

                        if isClaimed {
                            Text("CLAIMED")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.success)
                        } else {
                            Button("GRAB COUPON") {
                                Task {
                                    await viewModel.claimCoupon(
                                        code: couponCode,
                                        userId: userId,
                                        notification: notification
                                    )
                                }
                            }
                            .buttonStyle(EloraOutlineButton())
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(notification.isRead ? AppColors.line : AppColors.accent.opacity(0.35), lineWidth: 0.8)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await viewModel.markAsRead(notification: notification) }
        }
    }

    private func icon(for type: BuyerNotification.NotificationType) -> String {
        switch type {
        case .coupon: return "ticket"
        case .deal: return "tag"
        case .order: return "shippingbox"
        case .info: return "info.circle"
        }
    }

    private func color(for type: BuyerNotification.NotificationType) -> Color {
        switch type {
        case .coupon: return AppColors.accent
        case .deal: return AppColors.success
        case .order: return .blue
        case .info: return AppColors.muted
        }
    }

    private func couponSummary(_ coupon: Coupon) -> String {
        switch coupon.discountType {
        case .percentage:
            return "\(Int(coupon.discountValue))% off on qualifying orders"
        case .fixed:
            return "\(Int(coupon.discountValue)) off on qualifying orders"
        }
    }
}
