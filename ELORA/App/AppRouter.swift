import SwiftUI

// MARK: - Navigation Destination

enum AppDestination: Equatable {
    case productDetail(Product)
    case search
    case cart
    case checkout
    case orderHistory
    case notifications
    case savedAddresses
    case helpSupport
    case orderSuccess(String)
}

extension AppDestination: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .productDetail(let product):
            hasher.combine(0)
            hasher.combine(product.id)  // use the String? id directly
        case .search:
            hasher.combine(1)
        case .cart:
            hasher.combine(2)
        case .checkout:
            hasher.combine(3)
        case .orderHistory:
            hasher.combine(4)
        case .notifications:
            hasher.combine(5)
        case .savedAddresses:
            hasher.combine(6)
        case .helpSupport:
            hasher.combine(7)
        case .orderSuccess(let id):
            hasher.combine(8)
            hasher.combine(id)
        }
    }
}

// MARK: - Tab

enum AppTab: Int, CaseIterable {
    case home = 0
    case shop
    case favorites
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .shop: return "Shop"
        case .favorites: return "Favorites"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .shop: return "square.grid.2x2"
        case .favorites: return "heart"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .shop: return "square.grid.2x2.fill"
        case .favorites: return "heart.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Main Tab View (Router)

struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var cartVM = CartViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @ObservedObject var currencyService: CurrencyService

    @State private var selectedTab: AppTab = .home
    @State private var navigationPath = NavigationPath()
    @State private var isSidebarOpen = false

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack(path: $navigationPath) {
                ZStack(alignment: .bottom) {
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView(
                                currencyService: currencyService,
                                cartVM: cartVM,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onMenu: toggleSidebar,
                                onSearch: { selectTab(.shop) },
                                onCart: { navigateTo(.cart) }
                            )
                        case .shop:
                            ShopView(
                                currencyService: currencyService,
                                cartVM: cartVM,
                                favoritesVM: favoritesVM,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onMenu: toggleSidebar,
                                onCart: { navigateTo(.cart) }
                            )
                        case .favorites:
                            FavoritesView(
                                favoritesVM: favoritesVM,
                                cartVM: cartVM,
                                currencyService: currencyService,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onMenu: toggleSidebar
                            )
                        case .profile:
                            ProfileView(
                                authVM: authVM,
                                currencyService: currencyService,
                                onMenu: toggleSidebar,
                                onOrderHistory: { navigateTo(.orderHistory) },
                                onNotifications: { navigateTo(.notifications) },
                                onSavedAddresses: { navigateTo(.savedAddresses) },
                                onHelpSupport: { navigateTo(.helpSupport) }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    customTabBar
                }
                .navigationDestination(for: AppDestination.self) { dest in
                    destinationView(dest)
                }
            }
            if isSidebarOpen {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeSidebar()
                    }
                    .transition(.opacity)
            }

            if isSidebarOpen {
                sidebarMenu
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isSidebarOpen)
        // Cleanest fix — works for iOS 16 and below
        .onChange(of: authVM.userId) { newValue in
            cartVM.setUser(newValue)
            favoritesVM.setUser(newValue)
        }
        .onAppear {
            cartVM.setUser(authVM.userId)
            favoritesVM.setUser(authVM.userId)
        }
    }

    // MARK: - Navigation

    private func navigateTo(_ destination: AppDestination) {
        closeSidebar()
        navigationPath.append(destination)
    }

    private func selectTab(_ tab: AppTab) {
        selectedTab = tab
        navigationPath = NavigationPath()
        closeSidebar()
    }

    private func showCart() {
        navigationPath = NavigationPath()
        closeSidebar()
        navigationPath.append(AppDestination.cart)
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isSidebarOpen.toggle()
        }
    }

    private func closeSidebar() {
        guard isSidebarOpen else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isSidebarOpen = false
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .productDetail(let product):
            ProductDetailView(
                product: product,
                currencyService: currencyService,
                cartVM: cartVM,
                favoritesVM: favoritesVM,
                onBack: { navigationPath.removeLast() },
                onCart: { navigateTo(.cart) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .search:
            ShopView(
                currencyService: currencyService,
                cartVM: cartVM,
                favoritesVM: favoritesVM,
                onProduct: { navigateTo(.productDetail($0)) },
                onMenu: toggleSidebar,
                onCart: { navigateTo(.cart) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .cart:
            CartView(
                cartVM: cartVM,
                currencyService: currencyService,
                onMenu: toggleSidebar,
                onCheckout: {
                    guard !authVM.isGuest else {
                        authVM.errorMessage = "Please sign in to place an order."
                        authVM.signOut()
                        navigationPath = NavigationPath()
                        selectedTab = .home
                        return
                    }
                    navigateTo(.checkout)
                },
                onContinueShopping: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .checkout:
            CheckoutView(
                cartVM: cartVM,
                currencyService: currencyService,
                userId: authVM.userId ?? "",
                onOrderComplete: {
                    // Pop back to root
                    navigationPath = NavigationPath()
                    selectedTab = .home
                },
                onBack: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .orderHistory:
            OrderHistoryView(
                currencyService: currencyService,
                userId: authVM.userId ?? "",
                onBack: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .notifications:
            NotificationsView(
                userId: authVM.userId ?? "",
                onBack: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .savedAddresses:
            SavedAddressesView(
                userId: authVM.userId ?? "",
                onBack: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .helpSupport:
            HelpSupportView(
                onBack: { navigationPath.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .orderSuccess(let orderId):
            OrderSuccessView(
                orderId: orderId,
                total: "",
                onContinue: {
                    navigationPath = NavigationPath()
                    selectedTab = .home
                }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button(action: { selectTab(tab) }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(
                                    selectedTab == tab ? AppColors.accent : AppColors.muted
                                )

                            // Cart badge
                            if tab == .favorites && !favoritesVM.favorites.isEmpty {
                                Circle()
                                    .fill(AppColors.accent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -4)
                            }
                        }

                        Text(tab.title)
                            .font(.system(size: 10))
                            .foregroundColor(
                                selectedTab == tab ? AppColors.accent : AppColors.muted
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .background(
            AppColors.background
                .shadow(color: .black.opacity(0.3), radius: 8, y: -2)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }

    private var sidebarMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ELORA")
                    .font(AppFonts.tenor(28))
                    .foregroundColor(AppColors.text)

                Text(authVM.userEmail ?? (authVM.isGuest ? "Guest account" : "Welcome back"))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.muted)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, 72)
            .padding(.bottom, AppSpacing.lg)

            DiamondDivider(color: AppColors.line)
                .padding(.horizontal, AppSpacing.md)

            sidebarButton(title: "Home", icon: AppTab.home.icon, isSelected: selectedTab == .home) {
                selectTab(.home)
            }
            sidebarButton(title: "Shop", icon: AppTab.shop.icon, isSelected: selectedTab == .shop) {
                selectTab(.shop)
            }
            sidebarButton(
                title: "Favorites",
                icon: AppTab.favorites.icon,
                isSelected: selectedTab == .favorites
            ) {
                selectTab(.favorites)
            }
            sidebarButton(title: "Profile", icon: AppTab.profile.icon, isSelected: selectedTab == .profile) {
                selectTab(.profile)
            }
            sidebarButton(title: "My Cart", icon: "bag", badge: cartVM.itemCount) {
                showCart()
            }

            Spacer()

            Button(action: { authVM.signOut() }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                    Text("Sign Out")
                        .font(AppFonts.subheadline)
                }
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 280, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColors.line)
                .frame(width: 0.5)
        }
        .ignoresSafeArea()
    }

    private func sidebarButton(
        title: String,
        icon: String,
        badge: Int = 0,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 20)

                Text(title)
                    .font(AppFonts.subheadline)

                Spacer()

                if badge > 0 {
                    BadgeView(count: badge)
                }
            }
            .foregroundColor(isSelected ? AppColors.accent : AppColors.text)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.card : Color.clear)
        }
    }
}
