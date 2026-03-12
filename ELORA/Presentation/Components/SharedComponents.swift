import SwiftUI

// MARK: - Diamond Divider
struct DiamondDivider: View {
    var color: Color = AppColors.line

    var body: some View {
        HStack(spacing: 12) {
            line
            Diamond(size: 6)
                .foregroundColor(color)
            Diamond(size: 8)
                .foregroundColor(color)
            Diamond(size: 6)
                .foregroundColor(color)
            line
        }
        .padding(.vertical, AppSpacing.md)
    }

    private var line: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.5)
    }
}

struct Diamond: View {
    var size: CGFloat = 8

    var body: some View {
        Rectangle()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }
}

// MARK: - Top Bar
struct EloraTopBar: View {
    var title: String = "ELORA"
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    var onMenu: (() -> Void)? = nil
    var onSearch: (() -> Void)? = nil
    var onCart: (() -> Void)? = nil
    var cartBadge: Int = 0
    var style: BarStyle = .dark

    enum BarStyle {
        case dark, light
        var textColor: Color {
            self == .dark ? AppColors.text : AppColors.lightText
        }
    }

    var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(style.textColor)
                }
            } else {
                Button(action: { onMenu?() }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(style.textColor)
                }
            }

            Spacer()

            Text(title)
                .font(AppFonts.tenor(18))
                .foregroundColor(style.textColor)

            Spacer()

            HStack(spacing: 18) {
                if let onSearch = onSearch {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(style.textColor)
                    }
                }

                if let onCart = onCart {
                    Button(action: onCart) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bag")
                                .font(.system(size: 18))
                                .foregroundColor(style.textColor)

                            if cartBadge > 0 {
                                Text("\(cartBadge)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(AppColors.accent)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Page Dots
struct EloraPageDots: View {
    let count: Int
    let active: Int
    var activeColor: Color = AppColors.accent
    var inactiveColor: Color = AppColors.muted

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == active ? activeColor : inactiveColor)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Category Tabs
struct CategoryTabsView: View {
    let categories: [Category]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(categories) { cat in
                    Button(action: { selected = cat.id ?? "all" }) {
                        Text(cat.name.uppercased())
                            .font(AppFonts.caption)
                            .tracking(1.2)
                            .foregroundColor(
                                (cat.id ?? "all") == selected
                                ? AppColors.accent
                                : AppColors.muted
                            )
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Search Bar
struct EloraSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search products…"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.muted)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.muted)
                        .font(.system(size: 14))
                }
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

// MARK: - Loading View
struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
            Text(message)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.muted)

            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.muted)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(EloraPrimaryButton(isFullWidth: false))
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Badge
struct BadgeView: View {
    let count: Int
    var color: Color = AppColors.accent

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 18, minHeight: 18)
                .background(color)
                .clipShape(Circle())
        }
    }
}

// MARK: - Star Rating
struct StarRatingView: View {
    let rating: Double
    var maxStars: Int = 5
    var size: CGFloat = 14
    var color: Color = AppColors.accent

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxStars, id: \.self) { i in
                Image(systemName: starType(for: i))
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
    }

    private func starType(for index: Int) -> String {
        let threshold = Double(index) + 0.5
        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating >= threshold {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Product Tile
struct ProductTileView: View {
    let product: Product
    let currencyService: CurrencyService
    var onTap: (() -> Void)? = nil
    var onFavorite: (() -> Void)? = nil
    var isFavorite: Bool = false

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 6) {
                // Image
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: product.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            imageFallback
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            imageFallback
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(AppRadius.sm)

                    // Favorite Button
                    if onFavorite != nil {
                        Button(action: { onFavorite?() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(isFavorite ? AppColors.accent : AppColors.muted)
                                .padding(8)
                                .background(AppColors.background.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                }

                // Name
                Text(product.name)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)

                // Price
                Text(currencyService.formatted(product.price))
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.accent)

                // Rating
                if let rating = product.rating {
                    HStack(spacing: 4) {
                        StarRatingView(rating: rating, size: 10)
                        if let count = product.reviewCount {
                            Text("(\(count))")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.muted)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var imageFallback: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.title)
                .foregroundColor(AppColors.muted)
            Text(product.name)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
    }
}

// MARK: - Side Menu
struct SideMenuView: View {
    @Binding var isOpen: Bool
    var userEmail: String?
    var isGuest: Bool
    var onHome: () -> Void
    var onShop: () -> Void
    var onFavorites: () -> Void
    var onCart: () -> Void
    var onOrders: () -> Void
    var onProfile: () -> Void
    var onSignOut: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { isOpen = false } }
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ELORA")
                            .font(AppFonts.tenor(24))
                            .foregroundColor(AppColors.accent)

                        if let email = userEmail {
                            Text(email)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.muted)
                        } else if isGuest {
                            Text("Guest User")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.muted)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    DiamondDivider(color: AppColors.line)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 0) {
                        sideMenuItem(icon: "house", title: "Home", action: onHome)
                        sideMenuItem(icon: "square.grid.2x2", title: "Shop", action: onShop)
                        sideMenuItem(icon: "heart", title: "Favorites", action: onFavorites)
                        sideMenuItem(icon: "bag", title: "Cart", action: onCart)
                        sideMenuItem(icon: "shippingbox", title: "Orders", action: onOrders)
                        sideMenuItem(icon: "person", title: "Profile", action: onProfile)
                    }
                    .padding(.top, 8)

                    Spacer()

                    DiamondDivider(color: AppColors.line)
                        .padding(.horizontal, 16)

                    sideMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", action: onSignOut)
                        .padding(.bottom, 40)
                }
                .frame(width: 280)
                .background(AppColors.background)

                Spacer()
            }
            .offset(x: isOpen ? 0 : -300)
        }
        .animation(.easeInOut(duration: 0.25), value: isOpen)
    }

    private func sideMenuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { isOpen = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { action() }
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }
}
