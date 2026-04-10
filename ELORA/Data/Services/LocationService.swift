import Foundation
import CoreLocation
import Combine

/// Service that wraps CLLocationManager + CLGeocoder to get the user's
/// current GPS location and reverse-geocode it into an Address.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    @Published var detectedAddress: Address?
    @Published var isLocating = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Requests location permission, gets GPS coordinates, reverse-geocodes to Address.
    @MainActor
    func fetchCurrentAddress() async {
        isLocating = true
        errorMessage = nil
        detectedAddress = nil

        do {
            let location = try await requestLocation()
            let address = try await reverseGeocode(location)
            detectedAddress = address
        } catch let error as CLError where error.code == .denied {
            errorMessage = "Location access denied. Please enable in Settings."
        } catch {
            errorMessage = "Could not determine location."
        }

        isLocating = false
    }

    // MARK: - Private

    private func requestLocation() async throws -> CLLocation {
        let currentStatus = try await requestAuthorizationIfNeeded()
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            throw CLError(.denied)
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func requestAuthorizationIfNeeded() async throws -> CLAuthorizationStatus {
        let status = manager.authorizationStatus

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return status
        case .restricted, .denied:
            throw CLError(.denied)
        case .notDetermined:
            return try await withCheckedThrowingContinuation { continuation in
                self.authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            throw CLError(.denied)
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> Address {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let place = placemarks.first else {
            return .empty
        }

        return Address(
            fullName: "",
            phone: "",
            street: [place.subThoroughfare, place.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " "),
            city: place.locality ?? "",
            state: place.administrativeArea ?? "",
            zipCode: place.postalCode ?? "",
            country: place.country ?? ""
        )
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        guard let continuation = authorizationContinuation else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
            continuation.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        case .notDetermined:
            break
        @unknown default:
            continuation.resume(throwing: CLError(.denied))
            authorizationContinuation = nil
        }
    }
}
