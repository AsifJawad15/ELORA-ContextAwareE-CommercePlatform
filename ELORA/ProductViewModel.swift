import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()

    func fetchProducts() {
        isLoading = true
        errorMessage = nil

        db.collection("products")
            // If you have many docs without createdAt, temporarily comment this out:
            // .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Fetch error: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    return
                }

                let docs = snapshot?.documents ?? []

                let decoded = docs.compactMap { doc -> Product? in
                    do {
                        return try doc.data(as: Product.self)
                    } catch {
                        print("Decode failed for doc \(doc.documentID):", error.localizedDescription)
                        return nil
                    }
                }

                self.products = decoded
                self.isLoading = false

                if decoded.isEmpty && !docs.isEmpty {
                    self.errorMessage = "Docs exist, but decoding failed (field names mismatch)."
                }
            }
    }
}
