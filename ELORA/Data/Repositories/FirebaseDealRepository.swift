import Foundation
import FirebaseFirestore


final class FirebaseDealRepository: DealRepository {

    private let db = Firestore.firestore()
    private let collection = "deals"

    func fetchActiveDeals() async throws -> [Deal] {
        let snapshot = try await db.collection(collection)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Deal.self)
        }.filter { $0.isLive }
    }

    // MARK: - Admin CRUD

    func addDeal(_ data: [String: Any]) async throws -> String {
        let docRef = try await db.collection(collection).addDocument(data: data)
        return docRef.documentID
    }

    func updateDeal(id: String, data: [String: Any]) async throws {
        try await db.collection(collection).document(id).updateData(data)
    }

    func deleteDeal(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
