import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var authVM: AuthViewModel
    @ObservedObject var currencyService: CurrencyService
    @ObservedObject var favoritesVM: FavoritesViewModel
    var onOrderHistory: () -> Void
    var onFavorites: () -> Void = {}
    var onMenu: () -> Void = {}

    @State private var showAddresses = false
    @State private var showAddAddressForm = false
    @State private var editingAddress: Address?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(title: "PROFILE", onMenu: onMenu)

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Avatar
                        profileHeader

                        DiamondDivider(color: AppColors.line)
                            .padding(.horizontal)

                        // Currency Selector
                        currencySection

                        // Menu Items
                        profileMenu

                        // Sign Out
                        Button(action: { authVM.signOut() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("SIGN OUT")
                            }
                        }
                        .buttonStyle(EloraSecondaryButton())
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)

                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .task {
            if let userId = authVM.userId {
                await viewModel.loadProfile(userId: userId)
                await viewModel.loadOrders(userId: userId)
            }
        }
        .sheet(isPresented: $showAddresses) {
            SavedAddressesSheet(
                addresses: viewModel.profile?.savedAddresses ?? [],
                onAdd: { showAddAddressForm = true },
                onDelete: { index in
                    if let uid = authVM.userId {
                        Task { await viewModel.deleteAddress(at: index, userId: uid) }
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddAddressForm) {
            AddAddressSheet { address in
                if let uid = authVM.userId {
                    Task { await viewModel.addAddress(address, userId: uid) }
                }
                showAddAddressForm = false
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.accent)
            }

            // Name
            Text(viewModel.profile?.displayName ?? (authVM.isGuest ? "Guest" : "User"))
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)

            // Email
            Text(authVM.userEmail ?? "")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)

            if authVM.isGuest {
                Text("Sign in to save your data across devices")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Currency Section

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CURRENCY")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(CurrencyRate.supportedCurrencies.keys.sorted()), id: \.self) { code in
                        Button(action: {
                            currencyService.selectedCurrency = code
                            if let uid = authVM.userId {
                                Task {
                                    await viewModel.updateCurrency(code, userId: uid)
                                }
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(CurrencyRate.symbol(for: code))
                                    .font(.system(size: 18))
                                Text(code)
                                    .font(AppFonts.caption2)
                            }
                            .foregroundColor(
                                currencyService.selectedCurrency == code
                                ? .white : AppColors.text
                            )
                            .frame(width: 52, height: 52)
                            .background(
                                currencyService.selectedCurrency == code
                                ? AppColors.accent : AppColors.surface
                            )
                            .cornerRadius(AppRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(
                                        currencyService.selectedCurrency == code
                                        ? AppColors.accent : AppColors.line,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Menu

    private var profileMenu: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bag", title: "Order History", badge: viewModel.orders.count) {
                onOrderHistory()
            }
            menuRow(icon: "heart", title: "Favorites", badge: favoritesVM.favorites.count) {
                onFavorites()
            }
            menuRow(icon: "mappin.and.ellipse", title: "Saved Addresses", badge: viewModel.profile?.savedAddresses?.count ?? 0) {
                showAddresses = true
            }
            menuRow(icon: "bell", title: "Notifications", badge: 0) {}
            menuRow(icon: "questionmark.circle", title: "Help & Support", badge: 0) {}
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func menuRow(icon: String, title: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)

                Spacer()

                if badge > 0 {
                    BadgeView(count: badge)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.muted)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
        .overlay(
            Rectangle()
                .fill(AppColors.line)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var initials: String {
        let name = viewModel.profile?.displayName ?? authVM.userEmail ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Saved Addresses Sheet

struct SavedAddressesSheet: View {
    let addresses: [Address]
    var onAdd: () -> Void
    var onDelete: (Int) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if addresses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.muted)
                        Text("No Saved Addresses")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.text)
                        Text("Add an address for faster checkout")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.muted)
                    }
                } else {
                    List {
                        ForEach(Array(addresses.enumerated()), id: \.offset) { index, address in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.fullName)
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(AppColors.text)
                                Text(address.formatted)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.muted)
                                Text(address.phone)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.muted)
                            }
                            .listRowBackground(AppColors.surface)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { onDelete($0) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved Addresses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
    }
}

// MARK: - Add Address Sheet

struct AddAddressSheet: View {
    var onSave: (Address) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        addressField("Full Name", text: $fullName)
                        addressField("Phone", text: $phone)
                        addressField("Street Address", text: $street)
                        addressField("City", text: $city)
                        addressField("State / Province", text: $state)
                        addressField("Zip Code", text: $zipCode)
                        addressField("Country", text: $country)

                        Button(action: save) {
                            Text("SAVE ADDRESS")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(EloraPrimaryButton())
                        .disabled(fullName.isEmpty || street.isEmpty || city.isEmpty || country.isEmpty)
                        .padding(.top, AppSpacing.md)
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
    }

    private func addressField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)
            TextField(label, text: text)
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

    private func save() {
        let address = Address(
            fullName: fullName,
            phone: phone,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country
        )
        onSave(address)
        dismiss()
    }
}
