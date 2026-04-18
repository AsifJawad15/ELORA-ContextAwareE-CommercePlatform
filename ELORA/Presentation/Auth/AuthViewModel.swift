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
    @Published var infoMessage: String?
    @Published var requiresEmailVerification = false

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
                self?.isAuthenticated = (user?.isAnonymous == true) || (user?.isEmailVerified == true)
                self?.isGuest = user?.isAnonymous ?? false
            }
        }
    }

    // MARK: - Actions

    func signUp() async -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        guard Self.isValidEmail(normalizedEmail) else {
            errorMessage = "Please enter a valid email address."
            return false
        }

        isLoading = true
        clearMessages()

        do {
            let uid = try await authRepo.signUp(email: normalizedEmail, password: password)
            let profile = UserProfile(
                id: uid,
                email: normalizedEmail,
                displayName: displayName.isEmpty ? nil : displayName,
                preferredCurrency: "USD",
                createdAt: Date()
            )
            try await userRepo.createProfile(profile: profile)
            try await authRepo.sendEmailVerification()
            try authRepo.signOut()
            requiresEmailVerification = true
            infoMessage = "Verification email sent to \(normalizedEmail). Open the link, then sign in."
            clearForm(keepingEmail: normalizedEmail)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        return false
    }

    func signIn() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        guard Self.isValidEmail(normalizedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        clearMessages()

        do {
            let _ = try await authRepo.signIn(email: normalizedEmail, password: password)
            try await authRepo.reloadCurrentUser()

            guard authRepo.isCurrentUserEmailVerified else {
                try authRepo.signOut()
                requiresEmailVerification = true
                errorMessage = AuthError.emailNotVerified.localizedDescription
                infoMessage = "Check \(normalizedEmail) and tap the verification link before signing in."
                isLoading = false
                return
            }

            requiresEmailVerification = false
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func continueAsGuest() async {
        isLoading = true
        clearMessages()
        do {
            let _ = try await authRepo.signInAsGuest()
            requiresEmailVerification = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resendVerificationEmail() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password to resend the verification link."
            return
        }
        guard Self.isValidEmail(normalizedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        clearMessages()

        do {
            let _ = try await authRepo.signIn(email: normalizedEmail, password: password)
            try await authRepo.sendEmailVerification()
            try authRepo.signOut()
            requiresEmailVerification = true
            infoMessage = "A new verification email was sent to \(normalizedEmail)."
            clearForm(keepingEmail: normalizedEmail)
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

    private func clearForm(keepingEmail preservedEmail: String? = nil) {
        email = preservedEmail ?? ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
