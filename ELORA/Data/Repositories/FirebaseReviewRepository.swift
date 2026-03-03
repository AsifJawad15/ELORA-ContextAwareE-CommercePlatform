import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class FirebaseReviewRepository: ReviewRepository {

    private let db = Firestore.firestore()

    private func reviewsCollection(productId: String) -> CollectionReference {
        db.collection("products").document(productId).collection("reviews")
    }

    func fetchReviews(productId: String) async throws -> [Review] {
        let snapshot = try await reviewsCollection(productId: productId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Review.self)
        }
    }

    func addReview(productId: String, review: Review) async throws {
        let _ = try reviewsCollection(productId: productId).addDocument(from: review)

        // Update product's average rating
        let reviews = try await fetchReviews(productId: productId)
        let avgRating = Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
        try await db.collection("products").document(productId).updateData([
            "rating": avgRating,
            "reviewCount": reviews.count
        ])
    }
}
