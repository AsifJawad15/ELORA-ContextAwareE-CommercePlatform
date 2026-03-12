import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var price: Double
    var imageUrl: String
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

    enum CodingKeys: String, CodingKey {
        case id, name, price, imageUrl, imageurl, description
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        name = try c.decode(String.self, forKey: .name)
        price = try c.decode(Double.self, forKey: .price)
        imageUrl = (try? c.decode(String.self, forKey: .imageUrl))
            ?? (try? c.decode(String.self, forKey: .imageurl))
            ?? ""
        description = try? c.decode(String.self, forKey: .description)
        categoryId = try? c.decode(String.self, forKey: .categoryId)
        brand = try? c.decode(String.self, forKey: .brand)
        sizes = try? c.decode([String].self, forKey: .sizes)
        colors = try? c.decode([String].self, forKey: .colors)
        stock = try? c.decode(Int.self, forKey: .stock)
        rating = try? c.decode(Double.self, forKey: .rating)
        reviewCount = try? c.decode(Int.self, forKey: .reviewCount)
        isFeatured = try? c.decode(Bool.self, forKey: .isFeatured)
        createdAt = try? c.decode(Date.self, forKey: .createdAt)
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(price, forKey: .price)
        try c.encode(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encodeIfPresent(brand, forKey: .brand)
        try c.encodeIfPresent(sizes, forKey: .sizes)
        try c.encodeIfPresent(colors, forKey: .colors)
        try c.encodeIfPresent(stock, forKey: .stock)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encodeIfPresent(reviewCount, forKey: .reviewCount)
        try c.encodeIfPresent(isFeatured, forKey: .isFeatured)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
