import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

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
}
