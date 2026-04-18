import SwiftUI

struct CheckoutView: View {
    @StateObject private var viewModel = CheckoutViewModel()
    @ObservedObject var cartVM: CartViewModel
    @ObservedObject var currencyService: CurrencyService
    let userId: String
    var onOrderComplete: () -> Void
    var onBack: () -> Void
    @State private var isGatewayPresented = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if viewModel.orderPlaced {
                OrderSuccessView(
                    orderId: viewModel.orderId ?? "",
                    total: currencyService.formatted(
                        viewModel.placedOrderTotal ?? viewModel.total(subtotal: cartVM.subtotal)
                    ),
                    paymentMethod: viewModel.paymentMethodTitle,
                    paymentMessage: viewModel.paymentStatusMessage,
                    onContinue: onOrderComplete
                )
            } else {
                VStack(spacing: 0) {
                    // Top Bar
                    EloraTopBar(
                        title: "CHECKOUT",
                        showBack: true,
                        onBack: {
                            if viewModel.currentStep == .address {
                                onBack()
                            } else {
                                viewModel.previousStep()
                            }
                        }
                    )

                    // Progress Steps
                    checkoutProgress

                    DiamondDivider(color: AppColors.line)
                        .padding(.horizontal)

                    // Content
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            switch viewModel.currentStep {
                            case .address:
                                AddressFormView(
                                    address: $viewModel.address,
                                    savedAddresses: viewModel.savedAddresses,
                                    onSelectSavedAddress: { viewModel.applySavedAddress($0) }
                                )
                            case .payment:
                                PaymentFormView(
                                    paymentMethod: Binding(
                                        get: { viewModel.paymentMethod },
                                        set: { viewModel.selectPaymentMethod($0) }
                                    ),
                                    couponCode: $viewModel.couponCode,
                                    paymentMethods: viewModel.availablePaymentMethods,
                                    claimedCoupons: viewModel.claimedCoupons,
                                    appliedCoupon: viewModel.appliedCoupon,
                                    isPaymentAuthorized: viewModel.isPaymentAuthorized,
                                    paymentStatusMessage: viewModel.paymentStatusMessage,
                                    onSelectCoupon: { coupon in
                                        viewModel.applyClaimedCoupon(coupon, subtotal: cartVM.subtotal)
                                    },
                                    onApplyCoupon: {
                                        Task {
                                            await viewModel.applyCoupon(
                                                userId: userId,
                                                subtotal: cartVM.subtotal
                                            )
                                        }
                                    }
                                )
                            case .review:
                                OrderReviewView(
                                    items: cartVM.items,
                                    address: viewModel.address,
                                    paymentMethod: viewModel.paymentMethodTitle,
                                    couponCode: viewModel.appliedCoupon?.code,
                                    subtotal: cartVM.subtotal,
                                    shipping: viewModel.shippingCost,
                                    discount: viewModel.discount(for: cartVM.subtotal),
                                    total: viewModel.total(subtotal: cartVM.subtotal),
                                    currencyService: currencyService
                                )
                            }

                            // Error
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.error)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, 120)
                    }

                    Spacer()

                    // Bottom Action
                    bottomAction
                }
            }
        }
        .task {
            await viewModel.loadCheckoutData(userId: userId)
        }
        .fullScreenCover(isPresented: $isGatewayPresented) {
            if let method = viewModel.selectedPaymentMethod {
                MockPaymentGatewayView(
                    method: method,
                    amountText: currencyService.formatted(viewModel.total(subtotal: cartVM.subtotal)),
                    orderReference: viewModel.pendingCheckoutReference,
                    isProcessing: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onConfirm: { payerReference in
                        let confirmed = await viewModel.confirmGatewayPayment(
                            payerReference: payerReference,
                            subtotal: cartVM.subtotal
                        )
                        if confirmed {
                            viewModel.nextStep()
                        }
                        return confirmed
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Progress

    private var checkoutProgress: some View {
        HStack(spacing: 0) {
            ForEach(CheckoutViewModel.CheckoutStep.allCases, id: \.rawValue) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            step.rawValue <= viewModel.currentStep.rawValue
                            ? AppColors.accent
                            : AppColors.line
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(AppFonts.caption2)
                                .foregroundColor(.white)
                        )

                    Text(step.title)
                        .font(AppFonts.caption2)
                        .foregroundColor(
                            step.rawValue <= viewModel.currentStep.rawValue
                            ? AppColors.accent
                            : AppColors.muted
                        )
                }
                .frame(maxWidth: .infinity)

                if step.rawValue < CheckoutViewModel.CheckoutStep.allCases.count - 1 {
                    Rectangle()
                        .fill(
                            step.rawValue < viewModel.currentStep.rawValue
                            ? AppColors.accent
                            : AppColors.line
                        )
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Bottom Action

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Divider().background(AppColors.line)

            Button(action: {
                switch viewModel.currentStep {
                case .address:
                    if let addressError = viewModel.validateAddressFields() {
                        viewModel.errorMessage = addressError
                    } else {
                        Task { await viewModel.calculateShipping(subtotal: cartVM.subtotal) }
                        viewModel.nextStep()
                    }
                case .payment:
                    if let paymentError = viewModel.validatePaymentFields() {
                        viewModel.errorMessage = paymentError
                    } else if !viewModel.isPaymentAuthorized {
                        viewModel.errorMessage = nil
                        isGatewayPresented = true
                    } else {
                        viewModel.errorMessage = nil
                        viewModel.nextStep()
                    }
                case .review:
                    Task {
                        await viewModel.placeOrder(
                            userId: userId,
                            cartItems: cartVM.items,
                            subtotal: cartVM.subtotal
                        )
                        if viewModel.orderPlaced {
                            await cartVM.clearCart()
                        }
                    }
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(viewModel.currentStep == .review ? "PLACE ORDER" : "CONTINUE")
                }
            }
            .buttonStyle(EloraPrimaryButton())
            .disabled(viewModel.isLoading)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .background(AppColors.background)
    }
}

// MARK: - CheckoutStep Extension

extension CheckoutViewModel.CheckoutStep {
    var title: String {
        switch self {
        case .address: return "Address"
        case .payment: return "Payment"
        case .review: return "Review"
        }
    }
}
