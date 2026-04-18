import SwiftUI

struct SavedAddressesView: View {
    @StateObject private var viewModel = ProfileViewModel()
    let userId: String
    var onBack: () -> Void
    @State private var isEditorPresented = false
    @State private var editingIndex: Int?
    @State private var draftAddress = Address.empty

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                EloraTopBar(
                    title: "SAVED ADDRESSES",
                    showBack: true,
                    onBack: onBack
                )

                DiamondDivider(color: AppColors.line)
                    .padding(.horizontal)

                addAddressButton

                if viewModel.isLoading {
                    LoadingView()
                } else if addresses.isEmpty {
                    EmptyStateView(
                        icon: "mappin.and.ellipse",
                        title: "No Saved Addresses Yet",
                        subtitle: "Your checkout address will be saved here after you place an order."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(addresses.enumerated()), id: \.offset) { index, address in
                                addressCard(address: address, index: index)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile(userId: userId)
        }
        .sheet(isPresented: $isEditorPresented) {
            AddressEditorView(
                address: draftAddress,
                title: editingIndex == nil ? "Add Address" : "Edit Address",
                onSave: { address in
                    Task {
                        await viewModel.upsertAddress(address, at: editingIndex, userId: userId)
                    }
                }
            )
        }
    }

    private var addresses: [Address] {
        viewModel.profile?.savedAddresses ?? []
    }

    private func addressCard(address: Address, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(address.fullName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)

                Spacer()

                if index == 0 {
                    Text("DEFAULT")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.accent.opacity(0.12))
                        .cornerRadius(AppRadius.full)
                }
            }

            Text(address.formatted)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Text(address.phone)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.muted)

            HStack(spacing: 12) {
                Button(action: {
                    draftAddress = address
                    editingIndex = index
                    isEditorPresented = true
                }) {
                    Text("EDIT")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.text)
                }

                if index != 0 {
                    Button(action: {
                        Task { await viewModel.makeDefaultAddress(at: index, userId: userId) }
                    }) {
                        Text("SET AS DEFAULT")
                    }
                    .buttonStyle(EloraOutlineButton())
                }

                Spacer()

                Button(action: {
                    Task { await viewModel.removeAddress(at: index, userId: userId) }
                }) {
                    Text("REMOVE")
                        .font(AppFonts.caption)
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

    private var addAddressButton: some View {
        HStack {
            Spacer()
            Button(action: {
                editingIndex = nil
                draftAddress = Address.empty
                isEditorPresented = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("ADD ADDRESS")
                }
            }
            .buttonStyle(EloraOutlineButton())
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
        }
    }
}
