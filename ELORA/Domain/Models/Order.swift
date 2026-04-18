import Foundation
import FirebaseFirestore

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
    case packing
    case shipping
    case delivered
    case cancelled

    private var progressionIndex: Int {
        switch self {
        case .pending: return 0
        case .confirmed: return 1
        case .packing: return 2
        case .shipping: return 3
        case .delivered: return 4
        case .cancelled: return 5
        }
    }

    var displayName: String {
        switch self {
        case .shipping:
            return "Shipping"
        default:
            return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .packing: return "cube.box"
        case .shipping: return "truck.box"
        case .delivered: return "checkmark.seal"
        case .cancelled: return "xmark.circle"
        }
    }

    func canTransition(to newStatus: OrderStatus) -> Bool {
        guard newStatus != self else { return false }

        switch self {
        case .pending:
            return newStatus == .confirmed || newStatus == .cancelled
        case .confirmed:
            return newStatus == .packing || newStatus == .cancelled
        case .packing:
            return newStatus == .shipping || newStatus == .cancelled
        case .shipping:
            return newStatus == .delivered
        case .delivered, .cancelled:
            return false
        }
    }

    var nextAllowedStatuses: [OrderStatus] {
        OrderStatus.allCases.filter { canTransition(to: $0) }
            .sorted { $0.progressionIndex < $1.progressionIndex }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        switch raw {
        case "pending":
            self = .pending
        case "confirmed":
            self = .confirmed
        case "packing":
            self = .packing
        case "shipping", "shipped":
            self = .shipping
        case "delivered":
            self = .delivered
        case "cancelled":
            self = .cancelled
        default:
            self = .pending
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
