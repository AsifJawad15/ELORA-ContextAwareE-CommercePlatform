import Foundation
import FirebaseFirestoreSwift

struct Deal: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var subtitle: String?
    var imageUrl: String?
    var discountPercentage: Double?
    var categoryId: String?
    var productIds: [String]?
    var startsAt: Date?
    var endsAt: Date?
    var isActive: Bool

    var isLive: Bool {
        guard isActive else { return false }
        let now = Date()
        if let start = startsAt, start > now { return false }
        if let end = endsAt, end < now { return false }
        return true
    }
}
