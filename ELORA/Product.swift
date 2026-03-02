import Foundation
import FirebaseFirestoreSwift

struct Product: Identifiable, Decodable {
    @DocumentID var id: String?

    var name: String
    var price: Double
    var imageUrl: String
    var description: String?
    var categoryId: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, price, imageUrl, imageurl, description, categoryId, createdAt
    }

    init(
        id: String? = nil,
        name: String,
        price: Double,
        imageUrl: String,
        description: String? = nil,
        categoryId: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageUrl = imageUrl
        self.description = description
        self.categoryId = categoryId
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Firestore doc id is injected by @DocumentID; no need to decode id field.

        name = try c.decode(String.self, forKey: .name)
        price = try c.decode(Double.self, forKey: .price)

        // ✅ accept BOTH keys
        if let url = try c.decodeIfPresent(String.self, forKey: .imageUrl) {
            imageUrl = url
        } else if let url = try c.decodeIfPresent(String.self, forKey: .imageurl) {
            imageUrl = url
        } else {
            imageUrl = "" // prevents crash; you can also throw an error if you prefer
        }

        description = try c.decodeIfPresent(String.self, forKey: .description)
        categoryId = try c.decodeIfPresent(String.self, forKey: .categoryId)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
    }
}
