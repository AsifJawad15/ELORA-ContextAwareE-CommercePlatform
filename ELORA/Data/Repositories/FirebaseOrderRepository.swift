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
        // Try compound query first (requires composite index in Firestore)
        do {
            let snapshot = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap {
                try? $0.data(as: Order.self)
            }
        } catch {
            // Fallback: query without ordering if index not created yet
            let snapshot = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            let orders = snapshot.documents.compactMap {
                try? $0.data(as: Order.self)
            }
            return orders.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }
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
