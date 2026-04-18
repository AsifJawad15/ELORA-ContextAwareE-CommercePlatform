import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var featuredProducts: [Product] = []
    @Published var deals: [Deal] = []
    @Published var coupons: [Coupon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productRepo: ProductRepository
    private let dealRepo: DealRepository
    private let couponRepo: CouponRepository

    init(
        productRepo: ProductRepository = FirebaseProductRepository(),
        dealRepo: DealRepository = FirebaseDealRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository()
    ) {
        self.productRepo = productRepo
        self.dealRepo = dealRepo
        self.couponRepo = couponRepo
    }

    func loadHome() async {
        isLoading = true
        errorMessage = nil

        do {
            async let products = productRepo.fetchFeaturedProducts()
            async let activeDeals = dealRepo.fetchActiveDeals()
            async let activeCoupons = couponRepo.fetchActiveCoupons()

            featuredProducts = try await products
            deals = try await activeDeals
            let fetchedCoupons = try await activeCoupons
            coupons = fetchedCoupons.sorted { ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deal(for product: Product) -> Deal? {
        deals
            .filter { $0.applies(to: product) }
            .sorted { ($0.discountPercentage ?? 0) > ($1.discountPercentage ?? 0) }
            .first
    }
}
