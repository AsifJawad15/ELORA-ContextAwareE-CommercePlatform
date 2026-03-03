import Foundation

@MainActor
final class CartViewModel: ObservableObject {

    @Published var items: [CartItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cartRepo: CartRepository
    private var userId: String?

    init(cartRepo: CartRepository = FirebaseCartRepository()) {
        self.cartRepo = cartRepo
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }

    func setUser(_ userId: String?) {
        self.userId = userId
        if userId != nil {
            Task { await loadCart() }
        } else {
            items = []
        }
    }

    func loadCart() async {
        guard let userId = userId else { return }
        isLoading = true
        do {
            items = try await cartRepo.fetchCartItems(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addItem(_ item: CartItem) async {
        guard let userId = userId else { return }
        do {
            try await cartRepo.addToCart(userId: userId, item: item)
            await loadCart()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateQuantity(itemId: String, quantity: Int) async {
        guard let userId = userId else { return }
        do {
            try await cartRepo.updateQuantity(userId: userId, itemId: itemId, quantity: quantity)
            await loadCart()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(itemId: String) async {
        guard let userId = userId else { return }
        do {
            try await cartRepo.removeFromCart(userId: userId, itemId: itemId)
            await loadCart()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearCart() async {
        guard let userId = userId else { return }
        do {
            try await cartRepo.clearCart(userId: userId)
            items = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
