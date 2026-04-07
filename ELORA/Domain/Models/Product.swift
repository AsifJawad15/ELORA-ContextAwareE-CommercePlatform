import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Product: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var name: String
    var price: Double
    var imageUrl: String?
    var description: String?
    var categoryId: String?
    var brand: String?
    var sizes: [String]?
    var colors: [String]?
    var stock: Int?
    var rating: Double?
    var reviewCount: Int?
    var isFeatured: Bool?
    var createdAt: Date?
    
    var stableId: String {
        if let id, !id.isEmpty {
            return id
        }

        return [
            name.lowercased(),
            categoryId?.lowercased() ?? "",
            brand?.lowercased() ?? "",
            String(price)
        ]
        .map {
            $0.replacingOccurrences(of: "/", with: "-")
              .replacingOccurrences(of: " ", with: "-")
        }
        .joined(separator: "|")
    }



    // NOTE: 'id' is intentionally excluded — @DocumentID handles it automatically
    enum CodingKeys: String, CodingKey {
        case name, price, imageUrl, description
        case categoryId, brand, sizes, colors, stock
        case rating, reviewCount, isFeatured, createdAt
    }

    init(
        id: String? = nil,
        name: String,
        price: Double,
        imageUrl: String,
        description: String? = nil,
        categoryId: String? = nil,
        brand: String? = nil,
        sizes: [String]? = nil,
        colors: [String]? = nil,
        stock: Int? = nil,
        rating: Double? = nil,
        reviewCount: Int? = nil,
        isFeatured: Bool? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageUrl = imageUrl
        self.description = description
        self.categoryId = categoryId
        self.brand = brand
        self.sizes = sizes
        self.colors = colors
        self.stock = stock
        self.rating = rating
        self.reviewCount = reviewCount
        self.isFeatured = isFeatured
        self.createdAt = createdAt
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.stableId == rhs.stableId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stableId)
    }

}
