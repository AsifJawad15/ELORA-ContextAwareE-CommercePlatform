import SwiftUI

struct MockPaymentGatewayView: View {
    @Environment(\.dismiss) private var dismiss

    let method: MockPaymentGateway.PaymentMethodDefinition
    let amountText: String
    let orderReference: String
    var isProcessing: Bool
    var errorMessage: String?
    var onConfirm: (String) async -> Bool

    @State private var payerReference = ""

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(
                    title: "SECURE PAYMENT",
                    showBack: true,
                    onBack: { dismiss() }
                )

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        gatewayHeader
                        amountSummary
                        accountCard
                        payerField
                        helperPanel

                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, 140)
                }

                Spacer()

                Button(action: confirmPayment) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(method.confirmationLabel.uppercased())
                    }
                }
                .buttonStyle(EloraPrimaryButton())
                .disabled(isProcessing)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.background)
            }
        }
    }

    private var gatewayHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.accent.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: method.iconSystemName)
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.text)

                    Text(method.subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text("This is a local sandbox gateway for your project, but the flow is styled like a real payment handoff.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
        }
    }

    private var amountSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAYMENT SUMMARY")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            HStack {
                infoPill(title: "Amount", value: amountText)
                infoPill(title: "Order Ref", value: orderReference)
            }
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MERCHANT DETAILS")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            VStack(alignment: .leading, spacing: 12) {
                detailRow(label: "Merchant", value: "ELORA Sandbox Gateway")
                detailRow(label: method.accountLabel, value: method.accountNumber)
                detailRow(label: "Environment", value: "Project Demo Mode")
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.line, lineWidth: 0.5)
            )
        }
    }

    private var payerField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR CONFIRMATION")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            EloraTextField(
                icon: "person.text.rectangle",
                placeholder: method.payerFieldLabel,
                text: $payerReference
            )

            if method.id == "stripe" {
                Text("Try 4242, 1111, or 4444 for approval. Use 0002, 0005, or 0341 to simulate declines.")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.muted)
            }
        }
    }

    private var helperPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT STEP")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            Text("After this confirmation, ELORA will return you to checkout so you can review the order and submit it for admin confirmation.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)

            Text(value)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)

            Spacer()

            Text(value)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.trailing)
        }
    }

    private func confirmPayment() {
        Task {
            let didConfirm = await onConfirm(payerReference)
            if didConfirm {
                dismiss()
            }
        }
    }
}
