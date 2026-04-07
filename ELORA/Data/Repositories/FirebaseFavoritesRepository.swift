import Foundation
import FirebaseFirestore

final class FirebaseFavoritesRepository: FavoritesRepository {

    private let db = Firestore.firestore()

    private func favsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("favorites")
    }

    func fetchFavorites(userId: String) async throws -> [FavoriteItem] {
        let snapshot = try await favsCollection(userId: userId).getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: FavoriteItem.self)
        }
    }

    func addFavorite(userId: String, item: FavoriteItem) async throws {
        // Use productId as document ID to prevent duplicates
        try favsCollection(userId: userId).document(item.productId).setData(from: item)
    }

    func removeFavorite(userId: String, itemId: String) async throws {
        try await favsCollection(userId: userId).document(itemId).delete()
    }

    func isFavorite(userId: String, productId: String) async throws -> Bool {
        let doc = try await favsCollection(userId: userId).document(productId).getDocument()
        return doc.exists
    }
}
