import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var rating: Int // 1-5
    var title: String?
    var comment: String
    var createdAt: Date?

    var starString: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
}
