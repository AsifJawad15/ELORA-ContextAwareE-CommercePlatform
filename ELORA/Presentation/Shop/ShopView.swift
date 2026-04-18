import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    var onProduct: (Product) -> Void
    var onMenu: () -> Void
    var onCart: () -> Void

    @State private var showSearch = false

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding = AppSpacing.md + max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing)

            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar
                    EloraTopBar(
                        title: "SHOP",
                        onMenu: onMenu,
                        onSearch: { showSearch.toggle() },
                        onCart: onCart,
                        cartBadge: cartVM.itemCount
                    )

                    // Search bar (toggleable)
                    if showSearch {
                        EloraSearchBar(text: Binding(
                            get: { viewModel.searchQuery },
                            set: { viewModel.search($0) }
                        ))
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, AppSpacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Category Tabs
                    CategoryTabsView(
                        categories: viewModel.categories,
                        selected: Binding(
                            get: { viewModel.selectedCategory },
                            set: { viewModel.selectCategory($0) }
                        )
                    )

                    DiamondDivider(color: AppColors.line)
                        .padding(.horizontal)

                    // Products
                    if viewModel.isLoading {
                        LoadingView()
                    } else if viewModel.filteredProducts.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Products Found",
                            subtitle: "Try a different category or search term",
                            actionTitle: "Show All",
                            action: {
                                viewModel.selectCategory("all")
                                viewModel.search("")
                            }
                        )
                    } else {
                        ScrollView {
                            if !viewModel.deals.isEmpty {
                                activeDealsStrip
                                    .padding(.top, AppSpacing.sm)
                            }

                            // Product count
                            HStack {
                                Text("\(viewModel.filteredProducts.count) items")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.muted)
                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, AppSpacing.sm)

                            LazyVGrid(
                                columns: ProductGridLayout.columns,
                                alignment: .leading,
                                spacing: ProductGridLayout.spacing
                            ) {
                                ForEach(viewModel.filteredProducts, id: \.stableId) { product in
                                    ProductTileView(
                                        product: product,
                                        currencyService: currencyService,
                                        deal: viewModel.deal(for: product),
                                        onTap: { onProduct(product) },
                                        onFavorite: {
                                            Task { await favoritesVM.toggleFavorite(product: product) }
                                        },
                                        isFavorite: favoritesVM.isFavorite(productId: product.id ?? product.stableId)
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSearch)
        .task {
            await viewModel.loadProducts()
        }
    }

    private var activeDealsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.deals) { deal in
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppColors.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(deal.title)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.text)
                                .lineLimit(1)

                            Text(deal.badgeText ?? "LIVE")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.full)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.full)
                            .stroke(AppColors.line, lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
