import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var isGuest = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Form fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""

    private let authRepo: AuthRepository
    private let userRepo: UserRepository
    private var authListener: AuthStateDidChangeListenerHandle?

    init(authRepo: AuthRepository = FirebaseAuthRepository(),
         userRepo: UserRepository = FirebaseUserRepository()) {
        self.authRepo = authRepo
        self.userRepo = userRepo
        listenToAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.userId = user?.uid
                self?.userEmail = user?.email
                self?.isAuthenticated = user != nil
                self?.isGuest = user?.isAnonymous ?? false
            }
        }
    }

    // MARK: - Actions

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let uid = try await authRepo.signUp(email: email, password: password)
            let profile = UserProfile(
                id: uid,
                email: email,
                displayName: displayName.isEmpty ? nil : displayName,
                preferredCurrency: "USD",
                createdAt: Date()
            )
            try await userRepo.createProfile(profile: profile)
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let _ = try await authRepo.signIn(email: email, password: password)
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func continueAsGuest() async {
        isLoading = true
        errorMessage = nil
        do {
            let _ = try await authRepo.signInAsGuest()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try authRepo.signOut()
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }
}
