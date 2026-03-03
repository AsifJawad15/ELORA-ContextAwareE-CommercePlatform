import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var featuredProducts: [Product] = []
    @Published var deals: [Deal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productRepo: ProductRepository
    private let dealRepo: DealRepository

    init(productRepo: ProductRepository = FirebaseProductRepository(),
         dealRepo: DealRepository = FirebaseDealRepository()) {
        self.productRepo = productRepo
        self.dealRepo = dealRepo
    }

    func loadHome() async {
        isLoading = true
        errorMessage = nil

        do {
            async let products = productRepo.fetchFeaturedProducts()
            async let activeDeals = dealRepo.fetchActiveDeals()

            featuredProducts = try await products
            deals = try await activeDeals
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
