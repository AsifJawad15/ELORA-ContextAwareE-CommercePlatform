import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminLoginView: View {
    @Binding var isAdminLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onBackToUser: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.accent)

                    Text("ELORA")
                        .font(AppFonts.displayLarge)
                        .foregroundColor(AppColors.text)

                    Text("Admin Panel")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.muted)
                }

                // Form
                VStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.muted)
                        TextField("admin@elora.app", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.muted)
                        SecureField("Password", text: $password)
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

                    if let error = errorMessage {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.error)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { Task { await login() } }) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In as Admin")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(EloraPrimaryButton())
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }

                Spacer()

                // Back to user
                Button(action: onBackToUser) {
                    Text("Back to User Login")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accent)
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let uid = result.user.uid

            // Verify admin flag in Firestore
            let doc = try await Firestore.firestore()
                .collection("users").document(uid).getDocument()
            let profile = try doc.data(as: UserProfile.self)

            if profile.isAdmin == true {
                isAdminLoggedIn = true
            } else {
                // Not an admin — sign out and show error
                try? Auth.auth().signOut()
                errorMessage = "This account does not have admin privileges."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
