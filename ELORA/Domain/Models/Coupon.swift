import Foundation
import FirebaseFirestore

struct Coupon: Identifiable, Codable {
    @DocumentID var id: String?
    var code: String
    var discountType: DiscountType
    var discountValue: Double
    var minOrderAmount: Double?
    var maxDiscount: Double?
    var expiresAt: Date?
    var isActive: Bool

    enum DiscountType: String, Codable {
        case percentage
        case fixed
    }

    func discountAmount(for subtotal: Double) -> Double {
        guard isActive else { return 0 }
        if let minOrder = minOrderAmount, subtotal < minOrder { return 0 }
        if let expires = expiresAt, expires < Date() { return 0 }

        var amount: Double
        switch discountType {
        case .percentage:
            amount = subtotal * (discountValue / 100.0)
        case .fixed:
            amount = discountValue
        }

        if let cap = maxDiscount {
            amount = min(amount, cap)
        }
        return min(amount, subtotal)
    }
}
