import Foundation

/// Local pseudo payment gateway for project demos.
/// Loads realistic-looking payment and shipping rules from bundled JSON.
final class MockPaymentGateway {

    static let shared = MockPaymentGateway()

    struct ChargeResponse {
        let success: Bool
        let transactionId: String
        let approvalCode: String?
        let network: String
        let issuer: String
        let processorMessage: String
        let message: String
    }

    struct PaymentMethodDefinition: Identifiable, Decodable, Hashable {
        let id: String
        let title: String
        let subtitle: String
        let iconSystemName: String
        let accountLabel: String
        let accountNumber: String
        let payerFieldLabel: String
        let confirmationLabel: String
        let successMessage: String
    }

    private let configuration: Configuration

    private init(bundle: Bundle = .main) {
        configuration = Self.loadConfiguration(from: bundle)
    }

    func authorizePayment(
        amount: Double,
        currency: String,
        cardLastFour: String,
        orderId: String
    ) async throws -> ChargeResponse {
        let digits = normalizeDigits(cardLastFour)
        let rule = configuration.approvalRules.first { $0.cardLastFour == digits }
        let status = rule?.status ?? .approved
        let network = rule?.network ?? fallbackNetwork(for: digits)
        let issuer = rule?.issuer ?? fallbackIssuer(for: digits)

        try await Task.sleep(nanoseconds: delayNanoseconds(for: digits))

        let transactionId = makeTransactionId(orderId: orderId, digits: digits)
        let approvalCode = status == .approved ? makeApprovalCode(orderId: orderId, digits: digits) : nil
        let processorMessage = rule?.processorMessage ?? defaultProcessorMessage(for: status)
        let amountText = "\(CurrencyRate.symbol(for: currency))\(String(format: "%.2f", amount))"

        let message: String
        switch status {
        case .approved:
            let code = approvalCode ?? "------"
            message = "Approved \(amountText) on \(network) ending in \(digits). Auth \(code), \(issuer)."
        case .declined:
            message = "Declined by \(issuer): \(processorMessage). Try another card or Cash on Delivery."
        }

        return ChargeResponse(
            success: status == .approved,
            transactionId: transactionId,
            approvalCode: approvalCode,
            network: network,
            issuer: issuer,
            processorMessage: processorMessage,
            message: message
        )
    }

    func shippingQuote(country: String, subtotal: Double) -> Double {
        let normalizedCountry = normalizeCountry(country)
        let rate = configuration.shippingRates.first { rate in
            rate.countries.contains { normalizeCountry($0) == normalizedCountry }
        } ?? configuration.defaultShippingRate

        if subtotal >= rate.freeShippingThreshold {
            return 0
        }
        return rate.baseAmount
    }

    func paymentMethods() -> [PaymentMethodDefinition] {
        configuration.paymentMethods
    }

    func paymentMethod(id: String) -> PaymentMethodDefinition? {
        configuration.paymentMethods.first { $0.id == id }
    }

    func confirmPayment(
        methodId: String,
        payerReference: String,
        amount: Double,
        currency: String,
        orderId: String
    ) async throws -> ChargeResponse {
        guard let method = paymentMethod(id: methodId) else {
            throw MockGatewayError.invalidMethod
        }

        try await Task.sleep(nanoseconds: 850_000_000)

        let reference = payerReference.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedReference = reference.isEmpty ? "GUEST" : reference
        let transactionId = makeTransactionId(orderId: orderId, digits: normalizedReference)
        let approvalCode = makeApprovalCode(orderId: orderId, digits: normalizedReference)
        let amountText = "\(CurrencyRate.symbol(for: currency))\(String(format: "%.2f", amount))"

        return ChargeResponse(
            success: true,
            transactionId: transactionId,
            approvalCode: approvalCode,
            network: method.title,
            issuer: method.accountNumber,
            processorMessage: "Approved",
            message: "\(method.successMessage) \(amountText). Ref \(approvalCode)."
        )
    }

    private func fallbackNetwork(for digits: String) -> String {
        let networks = configuration.fallbackNetworks.isEmpty
            ? ["Visa", "Mastercard", "American Express"]
            : configuration.fallbackNetworks
        return networks[stableIndex(for: digits, upperBound: networks.count)]
    }

    private func fallbackIssuer(for digits: String) -> String {
        let issuers = configuration.fallbackIssuers.isEmpty
            ? ["Summit Trust Bank", "Citywide Commercial Bank", "Eastern Horizon Bank"]
            : configuration.fallbackIssuers
        return issuers[stableIndex(for: digits, upperBound: issuers.count)]
    }

    private func stableIndex(for digits: String, upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return stableNumber(from: digits) % upperBound
    }

    private func delayNanoseconds(for digits: String) -> UInt64 {
        let minDelay = configuration.processingDelayMs.minimum
        let maxDelay = max(configuration.processingDelayMs.maximum, minDelay)
        let span = maxDelay - minDelay
        let offset = span > 0 ? stableNumber(from: digits) % (span + 1) : 0
        return UInt64(minDelay + offset) * 1_000_000
    }

    private func stableNumber(from seed: String) -> Int {
        if let number = Int(seed.filter(\.isNumber)), number > 0 {
            return number
        }
        return seed.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
    }

    private func makeTransactionId(orderId: String, digits: String) -> String {
        let stamp = DateFormatter.gatewayDate.string(from: Date())
        let token = abs((orderId + digits).hashValue)
        let suffix = String(token % 1_000_000).leftPadded(to: 6, with: "0")
        return "MOCK-\(stamp)-\(suffix)"
    }

    private func makeApprovalCode(orderId: String, digits: String) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        var value = max(1, stableNumber(from: orderId + digits))
        var result = ""

        for _ in 0..<6 {
            result.append(alphabet[value % alphabet.count])
            value = max(1, value / 3)
        }

        return result
    }

    private func normalizeDigits(_ digits: String) -> String {
        let filtered = digits.filter(\.isNumber)
        if filtered.isEmpty { return "0000" }
        return String(filtered.suffix(4)).leftPadded(to: 4, with: "0")
    }

    private func normalizeCountry(_ country: String) -> String {
        country
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func defaultProcessorMessage(for status: ApprovalRule.Status) -> String {
        switch status {
        case .approved:
            return "Approved"
        case .declined:
            return "Do not honor"
        }
    }

    private static func loadConfiguration(from bundle: Bundle) -> Configuration {
        guard
            let url = bundle.url(forResource: "MockPaymentGateway", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let config = try? JSONDecoder().decode(Configuration.self, from: data)
        else {
            return .fallback
        }
        return config
    }
}

private extension MockPaymentGateway {
    struct Configuration: Decodable {
        let gateway: Gateway
        let merchant: Merchant
        let processingDelayMs: ProcessingDelay
        let paymentMethods: [PaymentMethodDefinition]
        let fallbackNetworks: [String]
        let fallbackIssuers: [String]
        let approvalRules: [ApprovalRule]
        let shippingRates: [ShippingRate]
        let defaultShippingRate: ShippingRate

        static let fallback = Configuration(
            gateway: Gateway(
                name: "ELORA Sandbox Gateway",
                processor: "NorthBridge Payments",
                acquirerBank: "Metropolitan Commerce Bank",
                terminalId: "ELR-TERM-1007"
            ),
            merchant: Merchant(
                displayName: "ELORA Atelier",
                descriptor: "ELORA ATELIER",
                merchantId: "ELORA-MOCK-001"
            ),
            processingDelayMs: ProcessingDelay(minimum: 700, maximum: 1300),
            paymentMethods: [
                PaymentMethodDefinition(
                    id: "stripe",
                    title: "Stripe",
                    subtitle: "Cards and hosted checkout",
                    iconSystemName: "creditcard.fill",
                    accountLabel: "Checkout Session",
                    accountNumber: "STRP-SESSION-4482",
                    payerFieldLabel: "Card holder or reference",
                    confirmationLabel: "Confirm Stripe Payment",
                    successMessage: "Stripe sandbox payment captured successfully."
                ),
                PaymentMethodDefinition(
                    id: "apple_pay",
                    title: "Apple Pay",
                    subtitle: "Mock wallet approval",
                    iconSystemName: "iphone.gen3",
                    accountLabel: "Merchant Token",
                    accountNumber: "APPLEPAY-MERCHANT-9090",
                    payerFieldLabel: "Apple Pay device reference",
                    confirmationLabel: "Confirm Apple Pay",
                    successMessage: "Apple Pay mock authorization completed."
                ),
                PaymentMethodDefinition(
                    id: "bkash",
                    title: "bKash",
                    subtitle: "Send to merchant wallet",
                    iconSystemName: "phone.connection.fill",
                    accountLabel: "Merchant Number",
                    accountNumber: "01701-ELORA",
                    payerFieldLabel: "Your bKash number",
                    confirmationLabel: "I Have Paid with bKash",
                    successMessage: "bKash mock transfer received."
                ),
                PaymentMethodDefinition(
                    id: "nagad",
                    title: "Nagad",
                    subtitle: "Pseudo mobile wallet checkout",
                    iconSystemName: "simcard.fill",
                    accountLabel: "Merchant Number",
                    accountNumber: "01888-ELORA",
                    payerFieldLabel: "Your Nagad number",
                    confirmationLabel: "I Have Paid with Nagad",
                    successMessage: "Nagad mock transfer received."
                ),
                PaymentMethodDefinition(
                    id: "cod",
                    title: "Cash on Delivery",
                    subtitle: "Pay after delivery confirmation",
                    iconSystemName: "banknote.fill",
                    accountLabel: "Payment",
                    accountNumber: "Pay on delivery",
                    payerFieldLabel: "Reference",
                    confirmationLabel: "Use Cash on Delivery",
                    successMessage: "Cash on delivery selected."
                )
            ],
            fallbackNetworks: ["Visa", "Mastercard", "American Express"],
            fallbackIssuers: ["Summit Trust Bank", "Citywide Commercial Bank", "Eastern Horizon Bank"],
            approvalRules: [
                ApprovalRule(
                    cardLastFour: "4242",
                    status: .approved,
                    network: "Visa",
                    issuer: "Summit Trust Bank",
                    processorMessage: "Approved"
                ),
                ApprovalRule(
                    cardLastFour: "0002",
                    status: .declined,
                    network: "Visa",
                    issuer: "Summit Trust Bank",
                    processorMessage: "Do not honor"
                )
            ],
            shippingRates: [
                ShippingRate(
                    countries: ["bangladesh", "bd"],
                    method: "standard",
                    baseAmount: 3.50,
                    freeShippingThreshold: 100
                ),
                ShippingRate(
                    countries: ["united states", "usa", "us"],
                    method: "standard",
                    baseAmount: 5.99,
                    freeShippingThreshold: 120
                )
            ],
            defaultShippingRate: ShippingRate(
                countries: [],
                method: "international",
                baseAmount: 9.99,
                freeShippingThreshold: 150
            )
        )
    }

    struct Gateway: Decodable {
        let name: String
        let processor: String
        let acquirerBank: String
        let terminalId: String
    }

    struct Merchant: Decodable {
        let displayName: String
        let descriptor: String
        let merchantId: String
    }

    struct ProcessingDelay: Decodable {
        let minimum: Int
        let maximum: Int
    }

    struct ApprovalRule: Decodable {
        enum Status: String, Decodable {
            case approved
            case declined
        }

        let cardLastFour: String
        let status: Status
        let network: String
        let issuer: String
        let processorMessage: String
    }

    struct ShippingRate: Decodable {
        let countries: [String]
        let method: String
        let baseAmount: Double
        let freeShippingThreshold: Double
    }

    enum MockGatewayError: LocalizedError {
        case invalidMethod

        var errorDescription: String? {
            switch self {
            case .invalidMethod:
                return "Invalid payment method."
            }
        }
    }
}

private extension DateFormatter {
    static let gatewayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

private extension String {
    func leftPadded(to length: Int, with character: Character) -> String {
        guard count < length else { return self }
        return String(repeating: String(character), count: length - count) + self
    }
}
