import Foundation
import FirebaseFirestore

final class FirestoreSeeder {
    static let shared = FirestoreSeeder()

    private init() {}

    private let db = Firestore.firestore()
    private let seededFlagKey = "didSeedProducts_v2" // change to v3/v4 if you want to seed again

    /// Seeds sample products into Firestore only once.
    func seedProductsIfNeeded(completion: ((Result<Void, Error>) -> Void)? = nil) {
        if UserDefaults.standard.bool(forKey: seededFlagKey) {
            completion?(.success(()))
            return
        }

        let products = makeSampleProducts()

        let batch = db.batch()

        // Use Auto-ID documents (recommended)
        for p in products {
            let docRef = db.collection("products").document() // Auto-ID
            batch.setData(productToDict(p), forDocument: docRef)
        }

        batch.commit { [weak self] error in
            if let error = error {
                completion?(.failure(error))
                return
            }

            if let key = self?.seededFlagKey {
                UserDefaults.standard.set(true, forKey: key)
            }
            completion?(.success(()))
        }
    }

    // MARK: - Sample Data

    private func makeSampleProducts() -> [Product] {
        // IMPORTANT:
        // Use DIRECT Google Drive URLs (not /file/d/.../view links)
        // Format:
        // https://drive.google.com/uc?export=view&id=FILE_ID

        return [
            Product(
                name: "Nike Air Max",
                price: 120,
                imageUrl: "https://drive.google.com/uc?export=view&id=YOUR_FILE_ID_1",
                description: "Comfortable running shoe",
                categoryId: "shoes",
                createdAt: Date()
            ),
            Product(
                name: "Adidas Ultraboost",
                price: 140,
                imageUrl: "https://drive.google.com/uc?export=view&id=YOUR_FILE_ID_2",
                description: "Premium sports shoe",
                categoryId: "shoes",
                createdAt: Date()
            ),
            Product(
                name: "Leather Wallet",
                price: 25,
                imageUrl: "https://drive.google.com/uc?export=view&id=YOUR_FILE_ID_3",
                description: "Minimal slim wallet",
                categoryId: "accessories",
                createdAt: Date()
            )
        ]
    }

    // MARK: - Mapping

    private func productToDict(_ p: Product) -> [String: Any] {
        // Do NOT store "id" in the document fields.
        // Firestore document ID will be mapped to Product.id via @DocumentID.
        var data: [String: Any] = [
            "name": p.name,
            "price": p.price,
            "imageUrl": p.imageUrl
        ]

        if let d = p.description { data["description"] = d }
        if let c = p.categoryId { data["categoryId"] = c }
        if let createdAt = p.createdAt { data["createdAt"] = Timestamp(date: createdAt) }

        return data
    }
}
