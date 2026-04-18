import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {

    enum CheckoutStep: Int, CaseIterable {
        case address = 0
        case payment = 1
        case review = 2
    }

    @Published var currentStep: CheckoutStep = .address
    @Published var address: Address = .empty
    @Published var paymentMethod: String = "stripe"
    @Published var couponCode: String = ""
    @Published var appliedCoupon: Coupon?
    @Published var shippingCost: Double = 0
    @Published var savedAddresses: [Address] = []
    @Published var claimedCouponCodes: Set<String> = []
    @Published var availableCoupons: [Coupon] = []
    @Published var availablePaymentMethods: [MockPaymentGateway.PaymentMethodDefinition] = []
    @Published var isPaymentAuthorized = false
    @Published var paymentStatusMessage: String?
    @Published var paymentTransactionId: String?
    @Published var pendingCheckoutReference: String = CheckoutViewModel.makeCheckoutReference()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var orderPlaced = false
    @Published var orderId: String?
    @Published var placedOrderTotal: Double?

    private let orderRepo: OrderRepository
    private let couponRepo: CouponRepository
    private let userRepo: UserRepository
    private let notificationRepo: NotificationRepository
    private let mockPaymentService: MockPaymentService
    private let currencyService: CurrencyService

    init(
        orderRepo: OrderRepository = FirebaseOrderRepository(),
        couponRepo: CouponRepository = FirebaseCouponRepository(),
        userRepo: UserRepository = FirebaseUserRepository(),
        notificationRepo: NotificationRepository = FirebaseNotificationRepository(),
        mockPaymentService: MockPaymentService = .shared,
        currencyService: CurrencyService = .shared
    ) {
        self.orderRepo = orderRepo
        self.couponRepo = couponRepo
        self.userRepo = userRepo
        self.notificationRepo = notificationRepo
        self.mockPaymentService = mockPaymentService
        self.currencyService = currencyService
        self.availablePaymentMethods = mockPaymentService.availablePaymentMethods()
        self.paymentMethod = availablePaymentMethods.first?.id ?? "stripe"
    }

    func discount(for subtotal: Double) -> Double {
        appliedCoupon?.discountAmount(for: subtotal) ?? 0
    }

    func total(subtotal: Double) -> Double {
        max(0, subtotal - discount(for: subtotal) + shippingCost)
    }

    var selectedPaymentMethod: MockPaymentGateway.PaymentMethodDefinition? {
        availablePaymentMethods.first { $0.id == paymentMethod }
    }

    var claimedCoupons: [Coupon] {
        availableCoupons.sorted { lhs, rhs in
            let lhsDate = lhs.expiresAt ?? .distantFuture
            let rhsDate = rhs.expiresAt ?? .distantFuture
            if lhsDate == rhsDate {
                return lhs.code < rhs.code
            }
            return lhsDate < rhsDate
        }
    }

    var paymentMethodTitle: String {
        selectedPaymentMethod?.title ?? Self.paymentMethodTitle(for: paymentMethod)
    }

    func nextStep() {
        if let next = CheckoutStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let previous = CheckoutStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previous
        }
    }

    func selectPaymentMethod(_ methodId: String) {
        guard paymentMethod != methodId else { return }
        paymentMethod = methodId
        resetPaymentAuthorization()
        errorMessage = nil
    }

    func validateAddress() -> Bool {
        validateAddressFields() == nil
    }

    func validateAddressFields() -> String? {
        let fullName = address.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard fullName.count >= 2 else {
            return "Please enter your full name."
        }
        let validName = fullName.range(
            of: #"^[A-Za-z][A-Za-z\s\.'-]{1,}$"#,
            options: .regularExpression
        ) != nil
        guard validName else {
            return "Full name can only contain letters, spaces, apostrophes, periods, and hyphens."
        }

        let phoneDigits = address.phone.filter(\.isNumber)
        guard (10...15).contains(phoneDigits.count) else {
            return "Please enter a valid phone number with 10 to 15 digits."
        }

        let street = address.street.trimmingCharacters(in: .whitespacesAndNewlines)
        guard street.count >= 5 else {
            return "Please enter a valid street address."
        }

        let city = address.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard city.count >= 2 else {
            return "Please enter a valid city."
        }

        let country = address.country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard country.count >= 2 else {
            return "Please enter a valid country."
        }

        let zip = address.zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !zip.isEmpty {
            let validZip = zip.range(
                of: #"^[A-Za-z0-9\s-]{3,10}$"#,
                options: .regularExpression
            ) != nil
            guard validZip else {
                return "Please enter a valid ZIP or postal code."
            }
        }

        return nil
    }

    func validatePaymentFields() -> String? {
        guard selectedPaymentMethod != nil else {
            return "Please select a payment method."
        }
        return nil
    }

    func loadCheckoutData(userId: String) async {
        availablePaymentMethods = mockPaymentService.availablePaymentMethods()
        if selectedPaymentMethod == nil {
            paymentMethod = availablePaymentMethods.first?.id ?? "stripe"
        }

        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            savedAddresses = []
            claimedCouponCodes = []
            availableCoupons = []
            return
        }

        do {
            async let profileRequest = userRepo.fetchProfile(userId: userId)
            async let couponRequest = couponRepo.fetchActiveCoupons()

            let profile = try await profileRequest
            let coupons = try await couponRequest

            let addresses = profile.savedAddresses ?? []
            savedAddresses = addresses
            claimedCouponCodes = Set((profile.claimedCouponCodes ?? []).map { $0.uppercased() })
            availableCoupons = coupons.reduce(into: [String: Coupon]()) { result, coupon in
                let key = coupon.code.uppercased()
                guard claimedCouponCodes.contains(key), result[key] == nil else { return }
                result[key] = coupon
            }
            .values
            .sorted { lhs, rhs in
                let lhsDate = lhs.expiresAt ?? .distantFuture
                let rhsDate = rhs.expiresAt ?? .distantFuture
                if lhsDate == rhsDate {
                    return lhs.code < rhs.code
                }
                return lhsDate < rhsDate
            }

            if address.isBlank, let firstAddress = addresses.first {
                applySavedAddress(firstAddress)
            }
        } catch {
            savedAddresses = []
            claimedCouponCodes = []
            availableCoupons = []
        }
    }

    func applyCoupon(userId: String, subtotal: Double) async {
        let normalized = couponCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let coupon = try await couponRepo.validateCoupon(code: normalized)
            try validateCouponValue(coupon, subtotal: subtotal)
            appliedCoupon = coupon
            couponCode = coupon.code.uppercased()
            try await persistClaimedCouponIfNeeded(code: coupon.code, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            appliedCoupon = nil
        }

        isLoading = false
    }

    func applyClaimedCoupon(_ coupon: Coupon, subtotal: Double) {
        do {
            try validateCouponValue(coupon, subtotal: subtotal)
            appliedCoupon = coupon
            couponCode = coupon.code.uppercased()
            errorMessage = nil
        } catch {
            appliedCoupon = nil
            errorMessage = error.localizedDescription
        }
    }

    func calculateShipping(subtotal: Double) async {
        do {
            shippingCost = try await mockPaymentService.calculateShipping(
                country: address.country,
                subtotal: subtotal
            )
        } catch {
            shippingCost = 9.99
        }
    }

    func applySavedAddress(_ savedAddress: Address) {
        address = savedAddress
        errorMessage = nil
    }

    func confirmGatewayPayment(payerReference: String, subtotal: Double) async -> Bool {
        guard let method = selectedPaymentMethod else {
            errorMessage = "Please select a payment method."
            return false
        }

        isLoading = true
        errorMessage = nil

        let trimmedReference = payerReference.trimmingCharacters(in: .whitespacesAndNewlines)
        let orderReference = pendingCheckoutReference
        let amount = total(subtotal: subtotal)
        let currency = currencyService.selectedCurrency

        do {
            let paymentResult: MockPaymentService.PaymentResult

            if method.id == "stripe" {
                let cardDigits = trimmedReference.filter(\.isNumber)
                let lastFour = String(cardDigits.suffix(4)).isEmpty ? "4242" : String(cardDigits.suffix(4))
                paymentResult = try await mockPaymentService.processPayment(
                    amount: amount,
                    currency: currency,
                    cardLastFour: lastFour,
                    orderId: orderReference
                )
            } else {
                paymentResult = try await mockPaymentService.confirmPayment(
                    methodId: method.id,
                    payerReference: trimmedReference.isEmpty ? "ELORA USER" : trimmedReference,
                    amount: amount,
                    currency: currency,
                    orderId: orderReference
                )
            }

            guard paymentResult.success else {
                resetPaymentAuthorization()
                errorMessage = paymentResult.message
                isLoading = false
                return false
            }

            isPaymentAuthorized = true
            paymentTransactionId = paymentResult.transactionId
            paymentStatusMessage = paymentResult.message
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            resetPaymentAuthorization()
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func placeOrder(userId: String, cartItems: [CartItem], subtotal: Double) async {
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please sign in before placing an order."
            return
        }
        if let addressError = validateAddressFields() {
            errorMessage = addressError
            return
        }
        if let paymentError = validatePaymentFields() {
            errorMessage = paymentError
            return
        }
        guard isPaymentAuthorized else {
            errorMessage = "Please complete your payment confirmation first."
            return
        }
        guard !cartItems.isEmpty else {
            errorMessage = "Your cart is empty."
            return
        }

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
        let now = Date()

        do {
            let order = Order(
                userId: userId,
                items: items,
                subtotal: subtotal,
                shippingCost: shippingCost,
                discount: disc,
                total: orderTotal,
                currency: currencyService.selectedCurrency,
                shippingAddress: address,
                paymentMethod: paymentMethod,
                status: .pending,
                createdAt: now,
                updatedAt: now
            )

            orderId = try await orderRepo.createOrder(order: order)
            placedOrderTotal = orderTotal
            try await persistAddressIfNeeded(userId: userId)
            try await createOrderReceivedNotification(userId: userId, orderId: orderId)
            orderPlaced = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func reset() {
        currentStep = .address
        address = .empty
        paymentMethod = availablePaymentMethods.first?.id ?? "stripe"
        couponCode = ""
        appliedCoupon = nil
        shippingCost = 0
        savedAddresses = []
        claimedCouponCodes = []
        availableCoupons = []
        resetPaymentAuthorization()
        pendingCheckoutReference = Self.makeCheckoutReference()
        orderPlaced = false
        orderId = nil
        placedOrderTotal = nil
        errorMessage = nil
    }

    private func validateCouponValue(_ coupon: Coupon, subtotal: Double) throws {
        if let minimum = coupon.minOrderAmount, subtotal < minimum {
            throw CouponError.minimumNotMet
        }

        guard coupon.discountAmount(for: subtotal) > 0 else {
            throw CouponError.invalidCode
        }
    }

    private func persistAddressIfNeeded(userId: String) async throws {
        let trimmedAddress = normalized(address)
        guard !trimmedAddress.isBlank else { return }

        var updatedAddresses = savedAddresses
        updatedAddresses.removeAll { normalized($0) == trimmedAddress }
        updatedAddresses.insert(trimmedAddress, at: 0)
        updatedAddresses = Array(updatedAddresses.prefix(5))

        try await userRepo.updateProfile(
            userId: userId,
            data: ["savedAddresses": updatedAddresses.map(\.firestoreData)]
        )

        savedAddresses = updatedAddresses
    }

    private func persistClaimedCouponIfNeeded(code: String, userId: String) async throws {
        let normalizedCode = code.uppercased()
        guard !normalizedCode.isEmpty else { return }
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if claimedCouponCodes.contains(normalizedCode) {
            if let coupon = appliedCoupon, !availableCoupons.contains(where: { $0.code.uppercased() == coupon.code.uppercased() }) {
                availableCoupons.append(coupon)
            }
            return
        }

        var updatedCodes = claimedCouponCodes
        updatedCodes.insert(normalizedCode)

        try await userRepo.updateProfile(
            userId: userId,
            data: ["claimedCouponCodes": Array(updatedCodes).sorted()]
        )

        claimedCouponCodes = updatedCodes
        if let coupon = appliedCoupon, !availableCoupons.contains(where: { $0.code.uppercased() == normalizedCode }) {
            availableCoupons.append(coupon)
        }
    }

    private func createOrderReceivedNotification(userId: String, orderId: String?) async throws {
        let notification = BuyerNotification(
            userId: userId,
            title: "Order Received",
            message: "Payment successful. Your order #\(String((orderId ?? "ORDER").prefix(8))) is waiting for admin confirmation.",
            type: .order,
            couponCode: nil,
            dealTitle: nil,
            orderId: orderId,
            isRead: false,
            createdAt: Date()
        )

        try await notificationRepo.createNotification(notification)
    }

    private func resetPaymentAuthorization() {
        isPaymentAuthorized = false
        paymentStatusMessage = nil
        paymentTransactionId = nil
        pendingCheckoutReference = Self.makeCheckoutReference()
    }

    private func normalized(_ address: Address) -> Address {
        Address(
            fullName: address.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: address.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            street: address.street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: address.city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: address.state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: address.zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: address.country.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func makeCheckoutReference() -> String {
        let raw = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return "ELR-\(String(raw.prefix(10)))"
    }

    static func paymentMethodTitle(for value: String) -> String {
        switch value {
        case "stripe":
            return "Stripe"
        case "apple_pay":
            return "Apple Pay"
        case "bkash":
            return "bKash"
        case "nagad":
            return "Nagad"
        case "cod":
            return "Cash on Delivery"
        default:
            return value.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
