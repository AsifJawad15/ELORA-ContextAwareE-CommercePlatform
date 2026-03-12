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
        let docRef = favsCollection(userId: userId).document(item.productId)
        let data: [String: Any] = [
            "productId": item.productId,
            "productName": item.productName,
            "productImageUrl": item.productImageUrl,
            "price": item.price,
            "addedAt": Timestamp(date: item.addedAt ?? Date())
        ]
        try await docRef.setData(data)
    }

    func removeFavorite(userId: String, itemId: String) async throws {
        try await favsCollection(userId: userId).document(itemId).delete()
    }

    func isFavorite(userId: String, productId: String) async throws -> Bool {
        let doc = try await favsCollection(userId: userId).document(productId).getDocument()
        return doc.exists
    }
}
