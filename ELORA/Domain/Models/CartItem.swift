import Foundation
import FirebaseFirestoreSwift

struct CartItem: Identifiable, Codable {
    @DocumentID var id: String?
    var productId: String
    var productName: String
    var productImageUrl: String
    var price: Double
    var quantity: Int
    var size: String?
    var color: String?
    var addedAt: Date?

    var subtotal: Double {
        price * Double(quantity)
    }
}
