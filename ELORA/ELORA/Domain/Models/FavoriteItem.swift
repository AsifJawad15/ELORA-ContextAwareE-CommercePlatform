import Foundation
import FirebaseFirestore

struct FavoriteItem: Identifiable, Codable {
    @DocumentID var id: String?
    var productId: String
    var productName: String
    var productImageUrl: String
    var price: Double
    var addedAt: Date?
}
