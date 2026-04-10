import Foundation
import FirebaseFirestore

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

    func applies(to product: Product) -> Bool {
        guard isLive else { return false }

        if let productIds, let productId = product.id, productIds.contains(productId) {
            return true
        }

        if let categoryId,
           let productCategoryId = product.categoryId,
           categoryId.caseInsensitiveCompare(productCategoryId) == .orderedSame {
            return true
        }

        return false
    }

    func discountedPrice(for originalPrice: Double) -> Double? {
        guard let discountPercentage, discountPercentage > 0 else { return nil }
        let multiplier = max(0, 1 - (discountPercentage / 100))
        return (originalPrice * multiplier * 100).rounded() / 100
    }

    var badgeText: String? {
        guard let discountPercentage, discountPercentage > 0 else { return nil }
        return "\(Int(discountPercentage))% OFF"
    }
}
