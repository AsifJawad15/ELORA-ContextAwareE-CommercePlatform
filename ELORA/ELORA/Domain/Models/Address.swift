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

    static let empty = Address(
        fullName: "", phone: "", street: "",
        city: "", state: "", zipCode: "", country: ""
    )
}
