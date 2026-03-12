import Foundation
import FirebaseFirestore

final class FirebaseCartRepository: CartRepository {

    private let db = Firestore.firestore()

    private func cartCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("cart")
    }

    func fetchCartItems(userId: String) async throws -> [CartItem] {
        let snapshot = try await cartCollection(userId: userId).getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: CartItem.self)
        }
    }

    func addToCart(userId: String, item: CartItem) async throws {
        // Check if same product+size+color already in cart
        let existing = try await fetchCartItems(userId: userId)
        if let found = existing.first(where: {
            $0.productId == item.productId &&
            $0.size == item.size &&
            $0.color == item.color
        }), let existingId = found.id {
            // Update quantity
            try await updateQuantity(
                userId: userId,
                itemId: existingId,
                quantity: found.quantity + item.quantity
            )
        } else {
            let _ = try cartCollection(userId: userId).addDocument(from: item)
        }
    }

    func updateQuantity(userId: String, itemId: String, quantity: Int) async throws {
        if quantity <= 0 {
            try await removeFromCart(userId: userId, itemId: itemId)
        } else {
            try await cartCollection(userId: userId).document(itemId)
                .updateData(["quantity": quantity])
        }
    }

    func removeFromCart(userId: String, itemId: String) async throws {
        try await cartCollection(userId: userId).document(itemId).delete()
    }

    func clearCart(userId: String) async throws {
        let snapshot = try await cartCollection(userId: userId).getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}
