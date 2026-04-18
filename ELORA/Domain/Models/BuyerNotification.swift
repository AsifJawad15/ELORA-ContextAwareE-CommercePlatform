import Foundation
import FirebaseFirestore

struct BuyerNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var message: String
    var type: NotificationType
    var couponCode: String?
    var dealTitle: String?
    var orderId: String?
    var isRead: Bool
    var createdAt: Date?

    enum NotificationType: String, Codable, CaseIterable {
        case coupon
        case deal
        case order
        case info
    }
}
