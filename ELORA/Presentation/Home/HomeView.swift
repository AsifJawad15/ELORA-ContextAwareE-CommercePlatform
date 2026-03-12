import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var cartVM: CartViewModel
    var onProduct: (Product) -> Void
    var onSearch: () -> Void
    var onCart: () -> Void
    var onMenu: () -> Void = {}

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Section
                    heroSection

                    DiamondDivider(color: AppColors.accent)
                        .padding(.horizontal)

                    // New Arrivals
                    sectionHeader(title: "NEW ARRIVAL", subtitle: "Explore our latest collection")

                    if viewModel.isLoading {
                        LoadingView(message: "Loading collection…")
                            .frame(height: 300)
                    } else {
                        productGrid
                    }

                    // Deals Banner
                    if !viewModel.deals.isEmpty {
                        dealsSection
                    }

                    DiamondDivider(color: AppColors.line)
                        .padding(.horizontal)

                    // Just For You
                    sectionHeader(title: "JUST FOR YOU", subtitle: "Curated picks based on trends")

                    justForYouGrid

                    Spacer(minLength: 100)
                }
            }

            // Top Bar overlay
            VStack {
                EloraTopBar(
                    title: "ELORA",
                    onMenu: onMenu,
                    onSearch: onSearch,
                    onCart: onCart,
                    cartBadge: cartVM.itemCount
                )
                .background(AppColors.background.opacity(0.9))
                Spacer()
            }
        }
        .task {
            await viewModel.loadHome()
            await currencyService.fetchRatesIfNeeded()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Cover image or gradient
            LinearGradient(
                colors: [AppColors.accent.opacity(0.3), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)

            VStack(spacing: 16) {
                Spacer()

                Text("LUXURY\nFASHION\n& ACCESSORIES")
                    .font(AppFonts.tenor(36))
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text("Explore the best of modern elegance")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.muted)

                Button(action: onSearch) {
                    Text("EXPLORE COLLECTION")
                }
                .buttonStyle(EloraPrimaryButton(isFullWidth: false))
                .padding(.bottom, 24)

                EloraPageDots(count: 3, active: 0)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.top, 50) // For top bar
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.featuredProducts.prefix(6)) { product in
                ProductTileView(
                    product: product,
                    currencyService: currencyService,
                    onTap: { onProduct(product) }
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Deals Section

    private var dealsSection: some View {
        VStack(spacing: 12) {
            DiamondDivider(color: AppColors.accent)
                .padding(.horizontal)

            ForEach(viewModel.deals) { deal in
                DealBannerView(deal: deal)
                    .padding(.horizontal, AppSpacing.md)
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Just For You

    private var justForYouGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.featuredProducts.suffix(4)) { product in
                ProductTileView(
                    product: product,
                    currencyService: currencyService,
                    onTap: { onProduct(product) }
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.text)
                .tracking(2)
            Text(subtitle)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
        }
        .padding(.vertical, AppSpacing.md)
    }
}

// MARK: - Deal Banner

struct DealBannerView: View {
    let deal: Deal

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(
                    LinearGradient(
                        colors: [AppColors.accent.opacity(0.8), AppColors.accent.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deal.title)
                        .font(AppFonts.headline)
                        .foregroundColor(.white)

                    if let subtitle = deal.subtitle {
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let pct = deal.discountPercentage {
                        Text("UP TO \(Int(pct))% OFF")
                            .font(AppFonts.tenor(20))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Image(systemName: "tag.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(AppSpacing.lg)
        }
        .frame(height: 120)
    }
}
