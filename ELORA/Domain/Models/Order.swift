import Foundation
import FirebaseFirestoreSwift

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var items: [OrderItem]
    var subtotal: Double
    var shippingCost: Double
    var discount: Double
    var total: Double
    var currency: String
    var shippingAddress: Address
    var paymentMethod: String
    var status: OrderStatus
    var createdAt: Date?
    var updatedAt: Date?

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}

struct OrderItem: Codable, Identifiable {
    var id: String { productId }
    var productId: String
    var productName: String
    var productImageUrl: String
    var price: Double
    var quantity: Int
    var size: String?
    var color: String?
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending
    case confirmed
    case shipped
    case delivered
    case cancelled

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .shipped: return "shippingbox"
        case .delivered: return "checkmark.seal"
        case .cancelled: return "xmark.circle"
        }
    }
}
