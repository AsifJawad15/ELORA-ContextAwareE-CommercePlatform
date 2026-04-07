import SwiftUI
import FirebaseAuth

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminViewModel()
    var onLogout: () -> Void

    @State private var selectedSection: AdminSection = .products

    enum AdminSection: String, CaseIterable {
        case products = "Products"
        case orders = "Orders"
        case coupons = "Coupons"
        case deals = "Deals"

        var icon: String {
            switch self {
            case .products: return "tag"
            case .orders: return "shippingbox"
            case .coupons: return "ticket"
            case .deals: return "flame"
            }
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                adminHeader

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                // Section Tabs
                sectionTabs

                // Messages
                messageBar

                // Content
                Group {
                    switch selectedSection {
                    case .products:
                        AdminProductsView(viewModel: viewModel)
                    case .orders:
                        AdminOrdersView(viewModel: viewModel)
                    case .coupons:
                        AdminCouponsView(viewModel: viewModel)
                    case .deals:
                        AdminDealsView(viewModel: viewModel)
                    }
                }
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - Header

    private var adminHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ADMIN PANEL")
                    .font(AppFonts.headline)
                    .tracking(2)
                    .foregroundColor(AppColors.accent)

                Text(Auth.auth().currentUser?.email ?? "Admin")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
            }

            Spacer()

            Button(action: onLogout) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                        .font(AppFonts.caption)
                }
                .foregroundColor(AppColors.error)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Section Tabs

    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AdminSection.allCases, id: \.rawValue) { section in
                    Button(action: { selectedSection = section }) {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(size: 14))
                            Text(section.rawValue)
                                .font(AppFonts.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .foregroundColor(
                            selectedSection == section ? .white : AppColors.text
                        )
                        .background(
                            selectedSection == section
                            ? AppColors.accent
                            : AppColors.surface
                        )
                        .cornerRadius(AppRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(
                                    selectedSection == section
                                    ? AppColors.accent : AppColors.line,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Message Bar

    @ViewBuilder
    private var messageBar: some View {
        if let success = viewModel.successMessage {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(success)
                Spacer()
                Button(action: { viewModel.clearMessages() }) {
                    Image(systemName: "xmark")
                }
            }
            .font(AppFonts.caption)
            .foregroundColor(.white)
            .padding(AppSpacing.sm)
            .background(AppColors.success.cornerRadius(AppRadius.sm))
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, 4)
        }

        if let error = viewModel.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error)
                Spacer()
                Button(action: { viewModel.clearMessages() }) {
                    Image(systemName: "xmark")
                }
            }
            .font(AppFonts.caption)
            .foregroundColor(.white)
            .padding(AppSpacing.sm)
            .background(AppColors.error.cornerRadius(AppRadius.sm))
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, 4)
        }
    }
}
