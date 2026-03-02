import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    var onProduct: (Product) -> Void
    var onCart: () -> Void

    @State private var showSearch = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                EloraTopBar(
                    title: "SHOP",
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
                    .padding(.horizontal, AppSpacing.md)
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
                        // Product count
                        HStack {
                            Text("\(viewModel.filteredProducts.count) items")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.muted)
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.filteredProducts) { product in
                                ProductTileView(
                                    product: product,
                                    currencyService: currencyService,
                                    onTap: { onProduct(product) },
                                    onFavorite: {
                                        Task { await favoritesVM.toggleFavorite(product: product) }
                                    },
                                    isFavorite: favoritesVM.isFavorite(productId: product.id ?? "")
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSearch)
        .task {
            await viewModel.loadProducts()
        }
    }
}
