import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {

    // Steps
    enum CheckoutStep: Int, CaseIterable {
        case address = 0
        case payment = 1
        case review = 2
    }

    @Published var currentStep: CheckoutStep = .address
    @Published var address: Address = .empty
    @Published var paymentMethod: String = "card"
    @Published var cardLastFour: String = ""
    @Published var couponCode: String = ""
    @Published var appliedCoupon: Coupon?
    @Published var shippingCost: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var orderPlaced = false
    @Published var orderId: String?

    private let orderRepo: OrderRepository
    private let couponRepo: CouponRepository
    private let paymentService: MockPaymentService
    private let currencyService: CurrencyService

    init(
        orderRepo: OrderRepository = FirebaseOrderRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository(),
        paymentService: MockPaymentService = .shared,
        currencyService: CurrencyService = .shared
    ) {
        self.orderRepo = orderRepo
        self.couponRepo = couponRepo
        self.paymentService = paymentService
        self.currencyService = currencyService
    }

    // MARK: - Computed

    func discount(for subtotal: Double) -> Double {
        appliedCoupon?.discountAmount(for: subtotal) ?? 0
    }

    func total(subtotal: Double) -> Double {
        let disc = discount(for: subtotal)
        return max(0, subtotal - disc + shippingCost)
    }

    // MARK: - Actions

    func nextStep() {
        if let next = CheckoutStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let prev = CheckoutStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    func validateAddress() -> Bool {
        !address.fullName.isEmpty &&
        !address.phone.isEmpty &&
        !address.street.isEmpty &&
        !address.city.isEmpty &&
        !address.country.isEmpty
    }

    func applyCoupon() async {
        guard !couponCode.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let coupon = try await couponRepo.validateCoupon(code: couponCode)
            appliedCoupon = coupon
        } catch {
            errorMessage = error.localizedDescription
            appliedCoupon = nil
        }
        isLoading = false
    }

    func calculateShipping() async {
        do {
            shippingCost = try await paymentService.calculateShipping(
                country: address.country,
                subtotal: 0 // will be passed when called
            )
        } catch {
            shippingCost = 9.99 // fallback
        }
    }

    func placeOrder(userId: String, cartItems: [CartItem], subtotal: Double) async {
        isLoading = true
        errorMessage = nil

        let items = cartItems.map { item in
            OrderItem(
                productId: item.productId,
                productName: item.productName,
                productImageUrl: item.productImageUrl,
                price: item.price,
                quantity: item.quantity,
                size: item.size,
                color: item.color
            )
        }

        let disc = discount(for: subtotal)
        let orderTotal = total(subtotal: subtotal)
        let currency = currencyService.selectedCurrency

        // Process mock payment
        do {
            let paymentResult = try await paymentService.processPayment(
                amount: orderTotal,
                currency: currency,
                cardLastFour: cardLastFour.isEmpty ? "0000" : cardLastFour,
                orderId: UUID().uuidString
            )

            guard paymentResult.success else {
                errorMessage = "Payment failed. Please try again."
                isLoading = false
                return
            }

            // Create order in Firestore
            let order = Order(
                userId: userId,
                items: items,
                subtotal: subtotal,
                shippingCost: shippingCost,
                discount: disc,
                total: orderTotal,
                currency: currency,
                shippingAddress: address,
                paymentMethod: paymentMethod,
                status: .confirmed,
                createdAt: Date()
            )

            orderId = try await orderRepo.createOrder(order: order)
            orderPlaced = true

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reset() {
        currentStep = .address
        address = .empty
        paymentMethod = "card"
        cardLastFour = ""
        couponCode = ""
        appliedCoupon = nil
        shippingCost = 0
        orderPlaced = false
        orderId = nil
        errorMessage = nil
    }
}
