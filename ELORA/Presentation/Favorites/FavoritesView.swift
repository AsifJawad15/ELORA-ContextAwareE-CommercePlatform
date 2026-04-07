import SwiftUI

struct FavoritesView: View {
    @ObservedObject var favoritesVM: FavoritesViewModel
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var currencyService: CurrencyService
    var onProduct: (Product) -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(title: "FAVORITES")

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                if favoritesVM.isLoading {
                    LoadingView()
                } else if favoritesVM.favorites.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "No Favorites Yet",
                        subtitle: "Tap the heart icon on products you love"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(favoritesVM.favorites) { item in
                                FavoriteItemRow(
                                    item: item,
                                    currencyService: currencyService,
                                    onTap: {
                                        // Create a minimal product to navigate
                                        let product = Product(
                                            id: item.productId,
                                            name: item.productName,
                                            price: item.price,
                                            imageUrl: item.productImageUrl
                                        )
                                        onProduct(product)
                                    },
                                    onAddToCart: {
                                        let cartItem = CartItem(
                                            productId: item.productId,
                                            productName: item.productName,
                                            productImageUrl: item.productImageUrl,
                                            price: item.price,
                                            quantity: 1,
                                            addedAt: Date()
                                        )
                                        Task { await cartVM.addItem(cartItem) }
                                    },
                                    onRemove: {
                                        Task {
                                            await favoritesVM.removeFavorite(
                                                productId: item.productId
                                            )
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await favoritesVM.loadFavorites()
        }
    }
}

// MARK: - Favorite Item Row

struct FavoriteItemRow: View {
    let item: FavoriteItem
    let currencyService: CurrencyService
    var onTap: () -> Void
    var onAddToCart: () -> Void
    var onRemove: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.productName)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)
                        .lineLimit(2)

                    Text(currencyService.formatted(item.price))
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.accent)

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: onAddToCart) {
                            HStack(spacing: 4) {
                                Image(systemName: "bag.badge.plus")
                                Text("Add to Cart")
                            }
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.accent)
                        }

                        Spacer()

                        Button(action: onRemove) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.error.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .overlay(
            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}
