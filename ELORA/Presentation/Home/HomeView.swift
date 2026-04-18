import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var cartVM: CartViewModel
    var onProduct: (Product) -> Void
    var onMenu: () -> Void
    var onSearch: () -> Void
    var onCart: () -> Void

    @State private var currentSlide: Int = 0
    private let autoScrollTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let gridHorizontalPadding = AppSpacing.md + max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing)

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
                            productGrid(horizontalPadding: gridHorizontalPadding)
                        }

                        if !viewModel.deals.isEmpty || !viewModel.coupons.isEmpty {
                            liveOffersSection
                        }

                        DiamondDivider(color: AppColors.line)
                            .padding(.horizontal)

                        // Just For You
                        sectionHeader(title: "JUST FOR YOU", subtitle: "Curated picks based on trends")

                        justForYouGrid(horizontalPadding: gridHorizontalPadding)

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
        }
        .task {
            await viewModel.loadHome()
            await currencyService.fetchRatesIfNeeded()
        }
    }

    // MARK: - Hero Section

    private var heroSlides: [Product] {
        Array(viewModel.featuredProducts.prefix(5))
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if heroSlides.isEmpty {
                // Fallback gradient when no products loaded yet
                LinearGradient(
                    colors: [AppColors.accent.opacity(0.3), AppColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
            } else {
                TabView(selection: $currentSlide) {
                    ForEach(Array(heroSlides.enumerated()), id: \.offset) { index, product in
                        ZStack(alignment: .bottom) {
                            // Product image background
                            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure, .empty:
                                    LinearGradient(
                                        colors: [AppColors.accent.opacity(0.3), AppColors.background],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                @unknown default:
                                    AppColors.surface
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                            // Dark gradient overlay for text readability
                            LinearGradient(
                                colors: [.clear, AppColors.background.opacity(0.85), AppColors.background],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 220)

                            // Product info overlay
                            VStack(spacing: 6) {
                                if let brand = product.brand {
                                    Text(brand.uppercased())
                                        .font(AppFonts.caption)
                                        .tracking(1.5)
                                        .foregroundColor(AppColors.accent)
                                }
                                Text(product.name)
                                    .font(AppFonts.tenor(24))
                                    .foregroundColor(AppColors.text)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                Text(currencyService.formatted(product.price))
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(AppColors.muted)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, 50)
                        }
                        .tag(index)
                        .onTapGesture { onProduct(product) }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)
                .onReceive(autoScrollTimer) { _ in
                    guard !heroSlides.isEmpty else { return }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentSlide = (currentSlide + 1) % heroSlides.count
                    }
                }
            }

            // Bottom content overlay
            VStack(spacing: 12) {
                Button(action: onSearch) {
                    Text("EXPLORE COLLECTION")
                }
                .buttonStyle(EloraPrimaryButton(isFullWidth: false))

                EloraPageDots(
                    count: max(heroSlides.count, 1),
                    active: currentSlide
                )
                .padding(.bottom, 16)
            }
        }
        .padding(.top, 50) // For top bar
    }

    // MARK: - Product Grid

    private func productGrid(horizontalPadding: CGFloat) -> some View {
        LazyVGrid(
            columns: ProductGridLayout.columns,
            alignment: .leading,
            spacing: ProductGridLayout.spacing
        ) {
            ForEach(viewModel.featuredProducts.prefix(6), id: \.stableId) { product in
                ProductTileView(
                    product: product,
                    currencyService: currencyService,
                    deal: viewModel.deal(for: product),
                    onTap: { onProduct(product) }
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - Live Offers

    private var liveOffersSection: some View {
        VStack(spacing: 16) {
            DiamondDivider(color: AppColors.accent)
                .padding(.horizontal)

            sectionHeader(title: "LIVE OFFERS", subtitle: "Fresh deals and coupons to use while ordering")

            if !viewModel.deals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.deals) { deal in
                            DealBannerView(deal: deal)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }

            if !viewModel.coupons.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.coupons) { coupon in
                            HomeCouponCard(coupon: coupon)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Just For You

    private func justForYouGrid(horizontalPadding: CGFloat) -> some View {
        LazyVGrid(
            columns: ProductGridLayout.columns,
            alignment: .leading,
            spacing: ProductGridLayout.spacing
        ) {
            ForEach(viewModel.featuredProducts.suffix(4), id: \.stableId) { product in
                ProductTileView(
                    product: product,
                    currencyService: currencyService,
                    deal: viewModel.deal(for: product),
                    onTap: { onProduct(product) }
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
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
                        colors: [AppColors.accent.opacity(0.92), AppColors.accent.opacity(0.55), AppColors.background.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("LIVE DEAL")
                        .font(AppFonts.caption2)
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.78))

                    Spacer()

                    Image(systemName: "flame.fill")
                        .foregroundColor(.white.opacity(0.78))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(deal.title)
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let subtitle = deal.subtitle {
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    if let pct = deal.discountPercentage {
                        Text("\(Int(pct))% OFF")
                            .font(AppFonts.tenor(26))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let endDate = deal.endsAt {
                        Text("Ends \(endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppFonts.caption2)
                            .foregroundColor(.white.opacity(0.78))
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .frame(height: 168)
    }
}

struct HomeCouponCard: View {
    let coupon: Coupon

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CHECKOUT COUPON")
                    .font(AppFonts.caption2)
                    .tracking(1.2)
                    .foregroundColor(AppColors.accent)

                Spacer()

                Image(systemName: "ticket.fill")
                    .foregroundColor(AppColors.accent.opacity(0.7))
            }

            Text(coupon.code)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)

            Text(summary)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack {
                if let minOrderAmount = coupon.minOrderAmount, minOrderAmount > 0 {
                    Text("Min \(Int(minOrderAmount))")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }

                Spacer()

                if let expiresAt = coupon.expiresAt {
                    Text(expiresAt.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 220, height: 136, alignment: .topLeading)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }

    private var summary: String {
        switch coupon.discountType {
        case .percentage:
            return "\(Int(coupon.discountValue))% off when you apply it at checkout"
        case .fixed:
            return "\(Int(coupon.discountValue)) off when you apply it at checkout"
        }
    }
}
