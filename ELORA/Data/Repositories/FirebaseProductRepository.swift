import Foundation
import FirebaseFirestore

final class FirebaseProductRepository: ProductRepository {

    private let db = Firestore.firestore()
    private let collection = "products"

    func fetchProducts() async throws -> [Product] {
        let snapshot = try await db.collection(collection)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Product.self)
        }
    }

    func fetchProducts(category: String) async throws -> [Product] {
        if category.lowercased() == "all" {
            return try await fetchProducts()
        }
        let snapshot = try await db.collection(collection)
            .whereField("categoryId", isEqualTo: category.lowercased())
            .getDocuments()
        return try snapshot.documents.compactMap {
            try $0.data(as: Product.self)
        }
    }

    func fetchProduct(id: String) async throws -> Product {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard let product = try? doc.data(as: Product.self) else {
            throw RepositoryError.notFound
        }
        return product
    }

    func searchProducts(query: String) async throws -> [Product] {
        // Firestore doesn't support full-text search natively.
        // We fetch all products and filter client-side for simplicity.
        let all = try await fetchProducts()
        let q = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            ($0.description?.lowercased().contains(q) ?? false) ||
            ($0.brand?.lowercased().contains(q) ?? false)
        }
    }

    func fetchFeaturedProducts() async throws -> [Product] {
        let snapshot = try await db.collection(collection)
            .whereField("isFeatured", isEqualTo: true)
            .limit(to: 10)
            .getDocuments()
        let featured = try snapshot.documents.compactMap {
            try $0.data(as: Product.self)
        }
        // If no featured flag set, return first 10
        if featured.isEmpty {
            return Array(try await fetchProducts().prefix(10))
        }
        return featured
    }

    // MARK: - Admin CRUD

    func addProduct(_ data: [String: Any]) async throws -> String {
        let docRef = try await db.collection(collection).addDocument(data: data)
        return docRef.documentID
    }

    func updateProduct(id: String, data: [String: Any]) async throws {
        try await db.collection(collection).document(id).updateData(data)
    }

    func deleteProduct(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}

enum RepositoryError: LocalizedError {
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notFound: return "Item not found."
        case .unauthorized: return "You are not authorized."
        }
    }
}
