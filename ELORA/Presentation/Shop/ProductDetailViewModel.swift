import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {

    @Published var product: Product?
    @Published var reviews: [Review] = []
    @Published var selectedSize: String?
    @Published var selectedColor: String?
    @Published var quantity: Int = 1
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productRepo: ProductRepository
    private let reviewRepo: ReviewRepository

    init(productRepo: ProductRepository = FirebaseProductRepository(),
         reviewRepo: ReviewRepository = FirebaseReviewRepository()) {
        self.productRepo = productRepo
        self.reviewRepo = reviewRepo
    }

    func loadProduct(_ product: Product) async {
        self.product = product
        selectedSize = product.sizes?.first
        selectedColor = product.colors?.first

        // Load reviews
        guard let productId = product.id else { return }
        do {
            reviews = try await reviewRepo.fetchReviews(productId: productId)
        } catch {
            print("Failed to load reviews: \(error)")
        }
    }

    var averageRating: Double {
        guard !reviews.isEmpty else { return product?.rating ?? 0 }
        return Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
    }

    func incrementQuantity() {
        if quantity < (product?.stock ?? 99) {
            quantity += 1
        }
    }

    func decrementQuantity() {
        if quantity > 1 {
            quantity -= 1
        }
    }

    func makeCartItem() -> CartItem? {
        guard let product = product else { return nil }
        return CartItem(
            productId: product.id ?? UUID().uuidString,
            productName: product.name,
            productImageUrl: product.imageUrl,
            price: product.price,
            quantity: quantity,
            size: selectedSize,
            color: selectedColor,
            addedAt: Date()
        )
    }
}
