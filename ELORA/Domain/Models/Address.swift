import Foundation

struct Address: Codable, Equatable {
    var fullName: String
    var phone: String
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String

    var formatted: String {
        "\(street), \(city), \(state) \(zipCode), \(country)"
    }

    var shortLabel: String {
        [street, city]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var isBlank: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var firestoreData: [String: Any] {
        [
            "fullName": fullName,
            "phone": phone,
            "street": street,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country
        ]
    }

    static let empty = Address(
        fullName: "", phone: "", street: "",
        city: "", state: "", zipCode: "", country: ""
    )
}
