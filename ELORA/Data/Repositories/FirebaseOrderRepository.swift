import Foundation
import FirebaseFirestore

final class FirebaseOrderRepository: OrderRepository {

    private let db = Firestore.firestore()
    private let collection = "orders"

    func createOrder(order: Order) async throws -> String {
        let docRef = try db.collection(collection).addDocument(from: order)
        return docRef.documentID
    }

    func fetchOrders(userId: String) async throws -> [Order] {
        // Keep this query index-free for buyer accounts, then sort client-side.
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let orders = snapshot.documents.compactMap {
            try? $0.data(as: Order.self)
        }

        return orders.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func fetchOrder(id: String) async throws -> Order {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard let order = try? doc.data(as: Order.self) else {
            throw RepositoryError.notFound
        }
        return order
    }

    func updateOrderStatus(orderId: String, status: OrderStatus) async throws {
        try await db.collection(collection).document(orderId)
            .updateData([
                "status": status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }

    func fetchAllOrders() async throws -> [Order] {
        let snapshot = try await db.collection(collection)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap {
            try? $0.data(as: Order.self)
        }
    }

    func deleteOrder(orderId: String) async throws {
        try await db.collection(collection).document(orderId).delete()
    }
}
