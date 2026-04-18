import SwiftUI
import MapKit

struct AddressFormView: View {
    @Binding var address: Address
    var savedAddresses: [Address] = []
    var onSelectSavedAddress: ((Address) -> Void)? = nil
    @StateObject private var locationService = LocationService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("SHIPPING ADDRESS")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            if !savedAddresses.isEmpty {
                savedAddressPicker
            }

            // Use Current Location button
            Button(action: {
                Task {
                    await locationService.fetchCurrentAddress()
                    if let detected = locationService.detectedAddress {
                        // Keep existing name & phone, fill in location fields
                        address.street = detected.street
                        address.city = detected.city
                        address.state = detected.state
                        address.zipCode = detected.zipCode
                        address.country = detected.country
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if locationService.isLocating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                    }
                    Text(locationService.isLocating ? "Detecting location…" : "Use Current Location")
                        .font(AppFonts.caption)
                }
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(AppColors.accent.opacity(0.1))
                .cornerRadius(AppRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(locationService.isLocating)

            if let error = locationService.errorMessage {
                Text(error)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.error)
            }

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
            .onChange(of: address.phone) { newValue in
                let filtered = newValue.filter { $0.isNumber || $0 == "+" }
                if filtered != newValue {
                    address.phone = filtered
                }
            }

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

            // Map preview when location is detected
            if let detected = locationService.detectedAddress,
               !detected.street.isEmpty {
                MapPreviewView(address: detected)
                    .frame(height: 150)
                    .cornerRadius(AppRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppColors.line, lineWidth: 0.5)
                    )
            }
        }
    }

    private var savedAddressPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("SAVED ADDRESSES")
                .font(AppFonts.caption)
                .tracking(1.2)
                .foregroundColor(AppColors.muted)

            ForEach(Array(savedAddresses.enumerated()), id: \.offset) { index, savedAddress in
                Button(action: { onSelectSavedAddress?(savedAddress) }) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: index == 0 ? "checkmark.circle.fill" : "mappin.circle")
                            .foregroundColor(index == 0 ? AppColors.accent : AppColors.muted)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(savedAddress.fullName)
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(AppColors.text)

                                if index == 0 {
                                    Text("DEFAULT")
                                        .font(AppFonts.caption2)
                                        .foregroundColor(AppColors.accent)
                                }
                            }

                            Text(savedAddress.formatted)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.leading)

                            Text(savedAddress.phone)
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.muted)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(
                                address == savedAddress ? AppColors.accent : AppColors.line,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
}

// MARK: - Map Preview

struct MapPreviewView: View {
    let address: Address
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: region.center)]) { pin in
            MapMarker(coordinate: pin.coordinate, tint: AppColors.accent)
        }
        .allowsHitTesting(false)
        .task {
            await geocodeAddress()
        }
    }

    private func geocodeAddress() async {
        let geocoder = CLGeocoder()
        let query = "\(address.street), \(address.city), \(address.state) \(address.zipCode), \(address.country)"
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            if let location = placemarks.first?.location {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            }
        } catch {
            // Silently fail - map just won't update
        }
    }
}

private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
