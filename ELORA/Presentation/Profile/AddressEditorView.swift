import SwiftUI

struct AddressEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State var address: Address
    var title: String
    var onSave: (Address) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                AddressFormView(address: $address)
                    .padding(AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.muted)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(address)
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}
