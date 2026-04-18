import Foundation
import SwiftUI
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
    private let userRepo: UserRepository
    private let notificationRepo: NotificationRepository

    init(
        productRepo: ProductRepository = FirebaseProductRepository(),
        orderRepo: OrderRepository = FirebaseOrderRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository(),
        dealRepo: DealRepository = FirebaseDealRepository(),
        userRepo: UserRepository = FirebaseUserRepository(),
        notificationRepo: NotificationRepository = FirebaseNotificationRepository()
    ) {
        self.productRepo = productRepo
        self.orderRepo = orderRepo
        self.couponRepo = couponRepo
        self.dealRepo = dealRepo
        self.userRepo = userRepo
        self.notificationRepo = notificationRepo
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
        clearMessages()
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "This product is missing its document ID, so it can't be deleted."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await productRepo.deleteProduct(id: id)
            await loadProducts()

            if products.contains(where: { $0.id == id }) {
                errorMessage = "The delete request completed, but the product is still in Firestore."
                return
            }

            successMessage = "Product deleted"
        } catch {
            errorMessage = error.localizedDescription
        }
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
        clearMessages()
        guard let currentOrder = orders.first(where: { $0.id == orderId }) else {
            errorMessage = "Order not found."
            return
        }
        guard currentOrder.status.canTransition(to: status) else {
            errorMessage = "Invalid status change from \(currentOrder.status.displayName) to \(status.displayName)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await orderRepo.updateOrderStatus(orderId: orderId, status: status)
            try await sendOrderStatusNotification(for: currentOrder, newStatus: status)
            successMessage = "Order status updated"
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
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
            try await notifyAllBuyers(
                title: "New Coupon: \(code.uppercased())",
                message: "Grab \(code.uppercased()) for your next order and save instantly at checkout.",
                type: .coupon,
                couponCode: code.uppercased()
            )
            successMessage = "Coupon added"
            // Send push notification for new coupon
            NotificationService.shared.scheduleLocalNotification(
                title: "New Coupon Available!",
                body: "Use code \(code.uppercased()) to get a discount on your next order.",
                delay: 2
            )
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
    func updateCoupon(_ coupon: Coupon) async {
        guard let id = coupon.id else { return }
        isLoading = true
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
            try await couponRepo.updateCoupon(id: id, data: data)
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
            try await notifyAllBuyers(
                title: "New Deal: \(title)",
                message: "\(title) is now live. Check the latest offer before it ends.",
                type: .deal,
                dealTitle: title
            )
            successMessage = "Deal added"
            // Send push notification for new deal
            NotificationService.shared.scheduleLocalNotification(
                title: "New Deal!",
                body: "\(title) — Up to \(Int(discountPercentage))% off! Limited time only.",
                delay: 2
            )
            NotificationService.shared.scheduleDealReminder(title: title, endsAt: endsAt)
            await loadDeals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    func updateDeal(_ deal: Deal) async {
        guard let id = deal.id else { return }
        isLoading = true
        var data: [String: Any] = [
            "title": deal.title,
            "isActive": deal.isActive
        ]
        if let subtitle = deal.subtitle { data["subtitle"] = subtitle }
        if let imageUrl = deal.imageUrl { data["imageUrl"] = imageUrl }
        if let pct = deal.discountPercentage { data["discountPercentage"] = pct }
        if let cat = deal.categoryId { data["categoryId"] = cat }
        if let s = deal.startsAt { data["startsAt"] = Timestamp(date: s) }
        if let e = deal.endsAt { data["endsAt"] = Timestamp(date: e) }
        do {
            try await dealRepo.updateDeal(id: id, data: data)
            successMessage = "Deal updated"
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

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func notifyAllBuyers(
        title: String,
        message: String,
        type: BuyerNotification.NotificationType,
        couponCode: String? = nil,
        dealTitle: String? = nil
    ) async throws {
        let profiles = try await userRepo.fetchAllProfiles()
        let notifications = profiles.compactMap { profile -> BuyerNotification? in
            guard profile.isAdmin != true, let userId = profile.id else { return nil }
            return BuyerNotification(
                userId: userId,
                title: title,
                message: message,
                type: type,
                couponCode: couponCode,
                dealTitle: dealTitle,
                orderId: nil,
                isRead: false,
                createdAt: Date()
            )
        }
        try await notificationRepo.createNotifications(notifications)
    }

    private func sendOrderStatusNotification(for order: Order, newStatus: OrderStatus) async throws {
        let title: String
        let message: String

        switch newStatus {
        case .confirmed:
            title = "Order Confirmed"
            message = "Your order \(shortOrderId(order.id)) has been confirmed by the admin."
        case .packing:
            title = "Order Packing"
            message = "Your order \(shortOrderId(order.id)) is now being packed."
        case .shipping:
            title = "Order Shipping"
            message = "Your order \(shortOrderId(order.id)) is on the way."
        case .delivered:
            title = "Order Delivered"
            message = "Your order \(shortOrderId(order.id)) has been delivered."
        case .cancelled:
            title = "Order Cancelled"
            message = "Your order \(shortOrderId(order.id)) was cancelled."
        case .pending:
            title = "Order Pending"
            message = "Your order \(shortOrderId(order.id)) is pending review."
        }

        let notification = BuyerNotification(
            userId: order.userId,
            title: title,
            message: message,
            type: .order,
            couponCode: nil,
            dealTitle: nil,
            orderId: order.id,
            isRead: false,
            createdAt: Date()
        )

        try await notificationRepo.createNotification(notification)
    }

    private func shortOrderId(_ orderId: String?) -> String {
        "#\(String((orderId ?? "ORDER").prefix(8)))"
    }
}
