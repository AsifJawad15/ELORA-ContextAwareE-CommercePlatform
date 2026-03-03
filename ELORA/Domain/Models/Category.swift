import Foundation
import FirebaseFirestoreSwift

struct Category: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var icon: String?
    var imageUrl: String?
    var order: Int?

    static let defaultCategories: [Category] = [
        Category(id: "all", name: "All"),
        Category(id: "apparel", name: "Apparel", icon: "tshirt"),
        Category(id: "dress", name: "Dress", icon: "figure.dress.line.vertical.figure"),
        Category(id: "tshirt", name: "T‑Shirt", icon: "tshirt"),
        Category(id: "bag", name: "Bag", icon: "bag"),
        Category(id: "shoes", name: "Shoes", icon: "shoe"),
        Category(id: "accessories", name: "Accessories", icon: "sparkles")
    ]
}
