import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel = ProductDetailViewModel()
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    var onBack: () -> Void
    var onCart: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Product Image
                    productImage

                    // Details
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Brand & Name
                        if let brand = product.brand {
                            Text(brand.uppercased())
                                .font(AppFonts.caption)
                                .tracking(1.5)
                                .foregroundColor(AppColors.muted)
                        }

                        Text(product.name)
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.text)

                        // Price & Rating
                        HStack {
                            Text(currencyService.formatted(product.price))
                                .font(AppFonts.title3)
                                .foregroundColor(AppColors.accent)

                            Spacer()

                            if viewModel.averageRating > 0 {
                                HStack(spacing: 4) {
                                    StarRatingView(rating: viewModel.averageRating, size: 14)
                                    Text("(\(viewModel.reviews.count))")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.muted)
                                }
                            }
                        }

                        DiamondDivider(color: AppColors.line)

                        // Description
                        if let desc = product.description {
                            Text(desc)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                        }

                        // Sizes
                        if let sizes = product.sizes, !sizes.isEmpty {
                            sizeSelector(sizes: sizes)
                        }

                        // Colors
                        if let colors = product.colors, !colors.isEmpty {
                            colorSelector(colors: colors)
                        }

                        // Quantity
                        quantitySelector

                        DiamondDivider(color: AppColors.line)

                        // Reviews
                        reviewsSection

                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)

                    Spacer(minLength: 120)
                }
            }

            // Top Bar overlay
            VStack {
                EloraTopBar(
                    showBack: true,
                    onBack: onBack,
                    onCart: onCart,
                    cartBadge: cartVM.itemCount
                )
                .background(AppColors.background.opacity(0.85))
                Spacer()
            }

            // Bottom Action Bar
            VStack {
                Spacer()
                bottomBar
            }
        }
        .task {
            await viewModel.loadProduct(product)
        }
    }

    // MARK: - Product Image

    private var productImage: some View {
        AsyncImage(url: URL(string: product.imageUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ZStack {
                    AppColors.surface
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.muted)
                        Text(product.name)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.muted)
                    }
                }
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.surface)
            @unknown default:
                AppColors.surface
            }
        }
        .frame(height: 440)
        .clipped()
        .padding(.top, 50)
    }

    // MARK: - Size Selector

    private func sizeSelector(sizes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SIZE")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sizes, id: \.self) { size in
                        Button(action: { viewModel.selectedSize = size }) {
                            Text(size)
                                .font(AppFonts.caption)
                                .foregroundColor(
                                    viewModel.selectedSize == size
                                    ? .white
                                    : AppColors.text
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.selectedSize == size
                                    ? AppColors.accent
                                    : Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .stroke(
                                            viewModel.selectedSize == size
                                            ? AppColors.accent
                                            : AppColors.line,
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(AppRadius.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Color Selector

    private func colorSelector(colors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COLOR")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    Button(action: { viewModel.selectedColor = color }) {
                        Text(color)
                            .font(AppFonts.caption)
                            .foregroundColor(
                                viewModel.selectedColor == color
                                ? .white : AppColors.text
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedColor == color
                                ? AppColors.accent : Color.clear
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .stroke(
                                        viewModel.selectedColor == color
                                        ? AppColors.accent : AppColors.line,
                                        lineWidth: 1
                                    )
                            )
                            .cornerRadius(AppRadius.sm)
                    }
                }
            }
        }
    }

    // MARK: - Quantity

    private var quantitySelector: some View {
        HStack(spacing: 16) {
            Text("QUANTITY")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            Spacer()

            HStack(spacing: 16) {
                Button(action: { viewModel.decrementQuantity() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.text)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .stroke(AppColors.line, lineWidth: 1)
                        )
                }

                Text("\(viewModel.quantity)")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                    .frame(width: 32)

                Button(action: { viewModel.incrementQuantity() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.text)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .stroke(AppColors.line, lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REVIEWS")
                    .font(AppFonts.caption)
                    .tracking(1.2)
                    .foregroundColor(AppColors.muted)
                Spacer()
                Text("\(viewModel.reviews.count) reviews")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
            }

            if viewModel.reviews.isEmpty {
                Text("No reviews yet. Be the first to review!")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.muted)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.reviews.prefix(3)) { review in
                    ReviewRow(review: review)
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Favorite
            Button(action: {
                Task { await favoritesVM.toggleFavorite(product: product) }
            }) {
                Image(systemName: favoritesVM.isFavorite(productId: product.id ?? "") ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(
                        favoritesVM.isFavorite(productId: product.id ?? "")
                        ? AppColors.accent : AppColors.text
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppColors.line, lineWidth: 1)
                    )
            }

            // Add to Cart
            Button(action: {
                if let item = viewModel.makeCartItem() {
                    Task { await cartVM.addItem(item) }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.badge.plus")
                    Text("ADD TO CART")
                }
            }
            .buttonStyle(EloraPrimaryButton())
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            AppColors.background
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.userName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                Spacer()
                StarRatingView(rating: Double(review.rating), size: 12)
            }

            if let title = review.title {
                Text(title)
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.text)
            }

            Text(review.comment)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
                .lineLimit(3)
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.sm)
    }
}
