import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var favorites: [FavoriteItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let favRepo: FavoritesRepository
    private var userId: String?

    init(favRepo: FavoritesRepository = FirebaseFavoritesRepository()) {
        self.favRepo = favRepo
    }

    func setUser(_ userId: String?) {
        self.userId = userId
        if userId != nil {
            Task { await loadFavorites() }
        } else {
            favorites = []
        }
    }

    func loadFavorites() async {
        guard let userId = userId else { return }
        isLoading = true
        errorMessage = nil
        do {
            favorites = try await favRepo.fetchFavorites(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func isFavorite(productId: String) -> Bool {
        favorites.contains { $0.productId == productId }
    }

    func toggleFavorite(product: Product) async {
        guard let userId = userId,
              let productId = product.id else { return }

        if isFavorite(productId: productId) {
            // Remove
            do {
                try await favRepo.removeFavorite(userId: userId, itemId: productId)
                favorites.removeAll { $0.productId == productId }
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Add
            let item = FavoriteItem(
                productId: productId,
                productName: product.name,
                productImageUrl: product.imageUrl,
                price: product.price,
                addedAt: Date()
            )
            do {
                try await favRepo.addFavorite(userId: userId, item: item)
                favorites.append(item)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeFavorite(productId: String) async {
        guard let userId = userId else { return }
        do {
            try await favRepo.removeFavorite(userId: userId, itemId: productId)
            favorites.removeAll { $0.productId == productId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
