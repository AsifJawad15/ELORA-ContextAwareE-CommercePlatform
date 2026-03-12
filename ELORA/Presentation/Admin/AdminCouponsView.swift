import SwiftUI

struct AdminCouponsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showAddForm = false
    @State private var editingCoupon: Coupon?

    var body: some View {
        VStack(spacing: 0) {
            // Stats
            HStack(spacing: 12) {
                couponStat("Total", "\(viewModel.coupons.count)", AppColors.accent)
                couponStat("Active", "\(viewModel.coupons.filter { $0.isActive }.count)", AppColors.success)
                couponStat("Expired", "\(viewModel.coupons.filter { !$0.isActive }.count)", AppColors.muted)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)

            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.coupons.isEmpty {
                EmptyStateView(
                    icon: "ticket",
                    title: "No Coupons",
                    subtitle: "Add a coupon to get started"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.coupons) { coupon in
                            AdminCouponCard(
                                coupon: coupon,
                                onEdit: { editingCoupon = coupon },
                                onDelete: {
                                    if let id = coupon.id {
                                        Task { await viewModel.deleteCoupon(id: id) }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 40)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showAddForm = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(AppColors.accent)
                    .clipShape(Circle())
                    .shadow(radius: 6)
            }
            .padding(AppSpacing.lg)
        }
        .sheet(isPresented: $showAddForm) {
            AdminCouponFormView(viewModel: viewModel, coupon: nil)
        }
        .sheet(item: $editingCoupon) { coupon in
            AdminCouponFormView(viewModel: viewModel, coupon: coupon)
        }
    }

    private func couponStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.sm)
    }
}

// MARK: - Coupon Card

struct AdminCouponCard: View {
    let coupon: Coupon
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(coupon.code)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)

                    Circle()
                        .fill(coupon.isActive ? AppColors.success : AppColors.error)
                        .frame(width: 8, height: 8)
                }

                Text(discountText)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accent)

                if let min = coupon.minOrderAmount {
                    Text("Min order: $\(min, specifier: "%.0f")")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.muted)
                }

                if let expires = coupon.expiresAt {
                    Text("Expires: \(expires, style: .date)")
                        .font(AppFonts.caption2)
                        .foregroundColor(expires < Date() ? AppColors.error : AppColors.muted)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.accent)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }

    private var discountText: String {
        switch coupon.discountType {
        case .percentage:
            var text = "\(Int(coupon.discountValue))% off"
            if let cap = coupon.maxDiscount { text += " (max $\(Int(cap)))" }
            return text
        case .fixed:
            return "$\(Int(coupon.discountValue)) off"
        }
    }
}

// MARK: - Coupon Form

struct AdminCouponFormView: View {
    @ObservedObject var viewModel: AdminViewModel
    let coupon: Coupon?
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var discountType: Coupon.DiscountType = .percentage
    @State private var discountValue = ""
    @State private var minOrderAmount = ""
    @State private var maxDiscount = ""
    @State private var expiresAt = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var hasExpiry = false
    @State private var isActive = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    formField("Coupon Code") {
                        TextField("e.g. SUMMER20", text: $code)
                            .textInputAutocapitalization(.characters)
                            .formStyle()
                    }

                    formField("Discount Type") {
                        Picker("Type", selection: $discountType) {
                            Text("Percentage").tag(Coupon.DiscountType.percentage)
                            Text("Fixed Amount").tag(Coupon.DiscountType.fixed)
                        }
                        .pickerStyle(.segmented)
                    }

                    formField(discountType == .percentage ? "Discount (%)" : "Discount ($)") {
                        TextField("e.g. 20", text: $discountValue)
                            .keyboardType(.decimalPad)
                            .formStyle()
                    }

                    formField("Min Order Amount (optional)") {
                        TextField("e.g. 50", text: $minOrderAmount)
                            .keyboardType(.decimalPad)
                            .formStyle()
                    }

                    if discountType == .percentage {
                        formField("Max Discount Cap (optional)") {
                            TextField("e.g. 30", text: $maxDiscount)
                                .keyboardType(.decimalPad)
                                .formStyle()
                        }
                    }

                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                        .foregroundColor(AppColors.text)
                        .tint(AppColors.accent)

                    if hasExpiry {
                        DatePicker("Expires At", selection: $expiresAt, displayedComponents: .date)
                            .foregroundColor(AppColors.text)
                            .tint(AppColors.accent)
                    }

                    Toggle("Active", isOn: $isActive)
                        .foregroundColor(AppColors.text)
                        .tint(AppColors.accent)

                    Button(action: save) {
                        Text(coupon == nil ? "Add Coupon" : "Update Coupon")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EloraPrimaryButton())
                    .disabled(code.isEmpty || discountValue.isEmpty)
                    .padding(.top, AppSpacing.md)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(coupon == nil ? "New Coupon" : "Edit Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard let c = coupon else { return }
        code = c.code
        discountType = c.discountType
        discountValue = "\(c.discountValue)"
        if let min = c.minOrderAmount { minOrderAmount = "\(min)" }
        if let max = c.maxDiscount { maxDiscount = "\(max)" }
        if let exp = c.expiresAt {
            hasExpiry = true
            expiresAt = exp
        }
        isActive = c.isActive
    }

    private func save() {
        guard let dv = Double(discountValue) else { return }
        var c = coupon ?? Coupon(
            code: "", discountType: .percentage, discountValue: 0, isActive: true
        )
        c.code = code.uppercased()
        c.discountType = discountType
        c.discountValue = dv
        c.minOrderAmount = Double(minOrderAmount)
        c.maxDiscount = discountType == .percentage ? Double(maxDiscount) : nil
        c.expiresAt = hasExpiry ? expiresAt : nil
        c.isActive = isActive

        Task {
            if coupon?.id != nil {
                await viewModel.updateCoupon(c)
            } else {
                await viewModel.addCoupon(c)
            }
            dismiss()
        }
    }

    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
            content()
        }
    }
}

// MARK: - Form TextField Style

private extension View {
    func formStyle() -> some View {
        self
            .font(AppFonts.body)
            .foregroundColor(AppColors.text)
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.line, lineWidth: 1)
            )
    }
}
