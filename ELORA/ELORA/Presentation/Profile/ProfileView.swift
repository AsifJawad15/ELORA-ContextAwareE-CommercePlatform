import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var authVM: AuthViewModel
    @ObservedObject var currencyService: CurrencyService
    var onOrderHistory: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(title: "PROFILE")

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Avatar
                        profileHeader

                        DiamondDivider(color: AppColors.line)
                            .padding(.horizontal)

                        // Currency Selector
                        currencySection

                        // Menu Items
                        profileMenu

                        // Sign Out
                        Button(action: { authVM.signOut() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("SIGN OUT")
                            }
                        }
                        .buttonStyle(EloraSecondaryButton())
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)

                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .task {
            if let userId = authVM.userId {
                await viewModel.loadProfile(userId: userId)
                await viewModel.loadOrders(userId: userId)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.accent)
            }

            // Name
            Text(viewModel.profile?.displayName ?? (authVM.isGuest ? "Guest" : "User"))
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)

            // Email
            Text(authVM.userEmail ?? "")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)

            if authVM.isGuest {
                Text("Sign in to save your data across devices")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Currency Section

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CURRENCY")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(CurrencyRate.supportedCurrencies.keys.sorted()), id: \.self) { code in
                        Button(action: {
                            currencyService.selectedCurrency = code
                            if let uid = authVM.userId {
                                Task {
                                    await viewModel.updateCurrency(code, userId: uid)
                                }
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(CurrencyRate.symbol(for: code))
                                    .font(.system(size: 18))
                                Text(code)
                                    .font(AppFonts.caption2)
                            }
                            .foregroundColor(
                                currencyService.selectedCurrency == code
                                ? .white : AppColors.text
                            )
                            .frame(width: 52, height: 52)
                            .background(
                                currencyService.selectedCurrency == code
                                ? AppColors.accent : AppColors.surface
                            )
                            .cornerRadius(AppRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(
                                        currencyService.selectedCurrency == code
                                        ? AppColors.accent : AppColors.line,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Menu

    private var profileMenu: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bag", title: "Order History", badge: viewModel.orders.count) {
                onOrderHistory()
            }
            menuRow(icon: "heart", title: "Favorites", badge: 0) {}
            menuRow(icon: "mappin.and.ellipse", title: "Saved Addresses", badge: 0) {}
            menuRow(icon: "bell", title: "Notifications", badge: 0) {}
            menuRow(icon: "questionmark.circle", title: "Help & Support", badge: 0) {}
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func menuRow(icon: String, title: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)

                Spacer()

                if badge > 0 {
                    BadgeView(count: badge)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.muted)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
        .overlay(
            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var initials: String {
        let name = viewModel.profile?.displayName ?? authVM.userEmail ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
