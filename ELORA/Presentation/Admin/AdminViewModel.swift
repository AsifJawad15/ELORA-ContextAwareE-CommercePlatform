import Foundation
import FirebaseFirestore

@MainActor
final class AdminViewModel: ObservableObject {

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var orders: [Order] = []
    @Published var coupons: [Coupon] = []
    @Published var deals: [Deal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let productRepo: ProductRepository
    private let orderRepo: OrderRepository
    private let couponRepo: CouponRepository
    private let dealRepo: DealRepository

    init(
        productRepo: ProductRepository = FirebaseProductRepository(),
        orderRepo: OrderRepository = FirebaseOrderRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository(),
        dealRepo: DealRepository = FirebaseDealRepository()
    ) {
        self.productRepo = productRepo
        self.orderRepo = orderRepo
        self.couponRepo = couponRepo
        self.dealRepo = dealRepo
    }

    // MARK: - Load All Data

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let p = productRepo.fetchProducts()
        async let o = orderRepo.fetchAllOrders()
        async let c = couponRepo.fetchActiveCoupons()
        async let d = dealRepo.fetchActiveDeals()
        do {
            products = try await p
            orders = try await o
            coupons = try await c
            deals = try await d
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Product CRUD

    func loadProducts() async {
        do {
            products = try await productRepo.fetchProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addProduct(
        name: String, price: Double, imageUrl: String, description: String,
        categoryId: String, brand: String, sizes: [String], colors: [String],
        stock: Int, isFeatured: Bool
    ) async {
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "name": name,
            "price": price,
            "imageUrl": imageUrl,
            "description": description,
            "categoryId": categoryId,
            "brand": brand,
            "colors": colors,
            "stock": stock,
            "isFeatured": isFeatured,
            "rating": 0.0,
            "reviewCount": 0,
            "createdAt": Timestamp(date: Date())
        ]
        if !sizes.isEmpty { data["sizes"] = sizes }
        do {
            let _ = try await productRepo.addProduct(data)
            successMessage = "Product added successfully"
            await loadProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProduct(
        id: String, name: String, price: Double, imageUrl: String,
        description: String, categoryId: String, brand: String,
        sizes: [String], colors: [String], stock: Int, isFeatured: Bool
    ) async {
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "name": name,
            "price": price,
            "imageUrl": imageUrl,
            "description": description,
            "categoryId": categoryId,
            "brand": brand,
            "colors": colors,
            "stock": stock,
            "isFeatured": isFeatured
        ]
        if !sizes.isEmpty { data["sizes"] = sizes }
        do {
            try await productRepo.updateProduct(id: id, data: data)
            successMessage = "Product updated successfully"
            await loadProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteProduct(id: String) async {
        isLoading = true
        do {
            try await productRepo.deleteProduct(id: id)
            products.removeAll { $0.id == id }
            successMessage = "Product deleted"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Order Management

    func loadOrders() async {
        do {
            orders = try await orderRepo.fetchAllOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateOrderStatus(orderId: String, status: OrderStatus) async {
        isLoading = true
        do {
            try await orderRepo.updateOrderStatus(orderId: orderId, status: status)
            successMessage = "Order status updated"
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteOrder(orderId: String) async {
        isLoading = true
        do {
            try await orderRepo.deleteOrder(orderId: orderId)
            orders.removeAll { $0.id == orderId }
            successMessage = "Order deleted"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Coupon CRUD

    func loadCoupons() async {
        do {
            coupons = try await couponRepo.fetchActiveCoupons()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCoupon(
        code: String, discountType: String, discountValue: Double,
        minOrderAmount: Double, maxDiscount: Double, expiresAt: Date
    ) async {
        isLoading = true
        let data: [String: Any] = [
            "code": code.uppercased(),
            "discountType": discountType,
            "discountValue": discountValue,
            "minOrderAmount": minOrderAmount,
            "maxDiscount": maxDiscount,
            "expiresAt": Timestamp(date: expiresAt),
            "isActive": true
        ]
        do {
            let _ = try await couponRepo.addCoupon(data)
            successMessage = "Coupon added"
            await loadCoupons()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteCoupon(id: String) async {
        isLoading = true
        do {
            try await couponRepo.deleteCoupon(id: id)
            coupons.removeAll { $0.id == id }
            successMessage = "Coupon deleted"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addCoupon(_ coupon: Coupon) async {
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "code": coupon.code.uppercased(),
            "discountType": coupon.discountType.rawValue,
            "discountValue": coupon.discountValue,
            "isActive": coupon.isActive
        ]
        if let min = coupon.minOrderAmount { data["minOrderAmount"] = min }
        if let max = coupon.maxDiscount { data["maxDiscount"] = max }
        if let exp = coupon.expiresAt { data["expiresAt"] = Timestamp(date: exp) }
        do {
            let _ = try await couponRepo.addCoupon(data)
            successMessage = "Coupon added"
            await loadCoupons()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateCoupon(_ coupon: Coupon) async {
        guard let couponId = coupon.id else { return }
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "code": coupon.code.uppercased(),
            "discountType": coupon.discountType.rawValue,
            "discountValue": coupon.discountValue,
            "isActive": coupon.isActive
        ]
        if let min = coupon.minOrderAmount { data["minOrderAmount"] = min }
        if let max = coupon.maxDiscount { data["maxDiscount"] = max }
        if let exp = coupon.expiresAt { data["expiresAt"] = Timestamp(date: exp) }
        do {
            try await couponRepo.updateCoupon(id: couponId, data: data)
            successMessage = "Coupon updated"
            await loadCoupons()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Deal CRUD

    func loadDeals() async {
        do {
            deals = try await dealRepo.fetchActiveDeals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDeal(
        title: String, subtitle: String, discountPercentage: Double,
        categoryId: String, startsAt: Date, endsAt: Date
    ) async {
        isLoading = true
        let data: [String: Any] = [
            "title": title,
            "subtitle": subtitle,
            "discountPercentage": discountPercentage,
            "categoryId": categoryId,
            "isActive": true,
            "startsAt": Timestamp(date: startsAt),
            "endsAt": Timestamp(date: endsAt)
        ]
        do {
            let _ = try await dealRepo.addDeal(data)
            successMessage = "Deal added"
            await loadDeals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteDeal(id: String) async {
        isLoading = true
        do {
            try await dealRepo.deleteDeal(id: id)
            deals.removeAll { $0.id == id }
            successMessage = "Deal deleted"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addDeal(_ deal: Deal) async {
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "title": deal.title,
            "isActive": deal.isActive
        ]
        if let subtitle = deal.subtitle { data["subtitle"] = subtitle }
        if let imageUrl = deal.imageUrl { data["imageUrl"] = imageUrl }
        if let dp = deal.discountPercentage { data["discountPercentage"] = dp }
        if let cid = deal.categoryId { data["categoryId"] = cid }
        if let starts = deal.startsAt { data["startsAt"] = Timestamp(date: starts) }
        if let ends = deal.endsAt { data["endsAt"] = Timestamp(date: ends) }
        do {
            let _ = try await dealRepo.addDeal(data)
            successMessage = "Deal added"
            await loadDeals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateDeal(_ deal: Deal) async {
        guard let dealId = deal.id else { return }
        isLoading = true
        errorMessage = nil
        var data: [String: Any] = [
            "title": deal.title,
            "isActive": deal.isActive
        ]
        if let subtitle = deal.subtitle { data["subtitle"] = subtitle }
        if let imageUrl = deal.imageUrl { data["imageUrl"] = imageUrl }
        if let dp = deal.discountPercentage { data["discountPercentage"] = dp }
        if let cid = deal.categoryId { data["categoryId"] = cid }
        if let starts = deal.startsAt { data["startsAt"] = Timestamp(date: starts) }
        if let ends = deal.endsAt { data["endsAt"] = Timestamp(date: ends) }
        do {
            try await dealRepo.updateDeal(id: dealId, data: data)
            successMessage = "Deal updated"
            await loadDeals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
