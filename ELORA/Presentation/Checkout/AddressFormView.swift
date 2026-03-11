import SwiftUI

struct AddressFormView: View {
    @Binding var address: Address

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("SHIPPING ADDRESS")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            EloraTextField(
                icon: "person",
                placeholder: "Full Name *",
                text: $address.fullName
            )

            EloraTextField(
                icon: "phone",
                placeholder: "Phone Number *",
                text: $address.phone,
                keyboardType: .phonePad
            )

            EloraTextField(
                icon: "house",
                placeholder: "Street Address *",
                text: $address.street
            )

            HStack(spacing: 12) {
                EloraTextField(
                    icon: "building.2",
                    placeholder: "City *",
                    text: $address.city
                )

                EloraTextField(
                    icon: "map",
                    placeholder: "State",
                    text: $address.state
                )
            }

            HStack(spacing: 12) {
                EloraTextField(
                    icon: "number",
                    placeholder: "ZIP Code",
                    text: $address.zipCode,
                    keyboardType: .numberPad
                )

                EloraTextField(
                    icon: "globe",
                    placeholder: "Country *",
                    text: $address.country
                )
            }
        }
    }
}
