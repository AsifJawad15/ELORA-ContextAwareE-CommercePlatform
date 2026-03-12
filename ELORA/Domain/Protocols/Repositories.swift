import Foundation
import Combine

// MARK: - Auth Repository
protocol AuthRepository {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    func signUp(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws -> String
    func signInAsGuest() async throws -> String
    func signOut() throws
    func deleteAccount() async throws
}

// MARK: - Product Repository
protocol ProductRepository {
    func fetchProducts() async throws -> [Product]
    func fetchProducts(category: String) async throws -> [Product]
    func fetchProduct(id: String) async throws -> Product
    func searchProducts(query: String) async throws -> [Product]
    func fetchFeaturedProducts() async throws -> [Product]
    func addProduct(_ data: [String: Any]) async throws -> String
    func updateProduct(id: String, data: [String: Any]) async throws
    func deleteProduct(id: String) async throws
}

// MARK: - Cart Repository
protocol CartRepository {
    func fetchCartItems(userId: String) async throws -> [CartItem]
    func addToCart(userId: String, item: CartItem) async throws
    func updateQuantity(userId: String, itemId: String, quantity: Int) async throws
    func removeFromCart(userId: String, itemId: String) async throws
    func clearCart(userId: String) async throws
}

// MARK: - Favorites Repository
protocol FavoritesRepository {
    func fetchFavorites(userId: String) async throws -> [FavoriteItem]
    func addFavorite(userId: String, item: FavoriteItem) async throws
    func removeFavorite(userId: String, itemId: String) async throws
    func isFavorite(userId: String, productId: String) async throws -> Bool
}

// MARK: - Order Repository
protocol OrderRepository {
    func createOrder(order: Order) async throws -> String
    func fetchOrders(userId: String) async throws -> [Order]
    func fetchAllOrders() async throws -> [Order]
    func fetchOrder(id: String) async throws -> Order
    func updateOrderStatus(orderId: String, status: OrderStatus) async throws
    func deleteOrder(orderId: String) async throws
}

// MARK: - Coupon Repository
protocol CouponRepository {
    func validateCoupon(code: String) async throws -> Coupon
    func fetchActiveCoupons() async throws -> [Coupon]
    func addCoupon(_ data: [String: Any]) async throws -> String
    func updateCoupon(id: String, data: [String: Any]) async throws
    func deleteCoupon(id: String) async throws
}

// MARK: - Review Repository
protocol ReviewRepository {
    func fetchReviews(productId: String) async throws -> [Review]
    func addReview(productId: String, review: Review) async throws
}

// MARK: - User Repository
protocol UserRepository {
    func fetchProfile(userId: String) async throws -> UserProfile
    func createProfile(profile: UserProfile) async throws
    func updateProfile(userId: String, data: [String: Any]) async throws
}

// MARK: - Deal Repository
protocol DealRepository {
    func fetchActiveDeals() async throws -> [Deal]
    func addDeal(_ data: [String: Any]) async throws -> String
    func updateDeal(id: String, data: [String: Any]) async throws
    func deleteDeal(id: String) async throws
}
