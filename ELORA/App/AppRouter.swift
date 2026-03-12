import SwiftUI

// MARK: - Navigation Destination

enum AppDestination: Hashable {
    case productDetail(Product)
    case search
    case cart
    case checkout
    case orderHistory
    case orderSuccess(String)
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
    @State private var showSideMenu = false

    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                ZStack(alignment: .bottom) {
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView(
                                currencyService: currencyService,
                                cartVM: cartVM,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onSearch: { selectedTab = .shop },
                                onCart: { navigateTo(.cart) },
                                onMenu: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu = true } }
                            )
                        case .shop:
                            ShopView(
                                currencyService: currencyService,
                                cartVM: cartVM,
                                favoritesVM: favoritesVM,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onCart: { navigateTo(.cart) },
                                onMenu: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu = true } }
                            )
                        case .favorites:
                            FavoritesView(
                                favoritesVM: favoritesVM,
                                cartVM: cartVM,
                                currencyService: currencyService,
                                onProduct: { navigateTo(.productDetail($0)) },
                                onMenu: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu = true } }
                            )
                        case .profile:
                            ProfileView(
                                authVM: authVM,
                                currencyService: currencyService,
                                favoritesVM: favoritesVM,
                                onOrderHistory: { navigateTo(.orderHistory) },
                                onFavorites: { selectedTab = .favorites },
                                onMenu: { withAnimation(.easeInOut(duration: 0.25)) { showSideMenu = true } }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Custom Tab Bar
                    customTabBar
                }
                .navigationDestination(for: AppDestination.self) { dest in
                    destinationView(dest)
                }
            }

            // Side Menu Overlay
            SideMenuView(
                isOpen: $showSideMenu,
                userEmail: authVM.userEmail,
                isGuest: authVM.isGuest,
                onHome: { selectedTab = .home },
                onShop: { selectedTab = .shop },
                onFavorites: { selectedTab = .favorites },
                onCart: { navigateTo(.cart) },
                onOrders: { navigateTo(.orderHistory) },
                onProfile: { selectedTab = .profile },
                onSignOut: { authVM.signOut() }
            )
        }
        .onChange(of: authVM.userId) { oldValue, newValue in
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
        navigationPath.append(destination)
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
                onCart: { navigateTo(.cart) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .cart:
            CartView(
                cartVM: cartVM,
                currencyService: currencyService,
                onCheckout: { navigateTo(.checkout) },
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
                Button(action: { selectedTab = tab }) {
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
}
