import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Logo / Header
                    VStack(spacing: 8) {
                        Text("ELORA")
                            .font(AppFonts.tenor(42))
                            .foregroundColor(AppColors.accent)

                        Text("LUXURY FASHION & ACCESSORIES")
                            .font(AppFonts.caption)
                            .tracking(2)
                            .foregroundColor(AppColors.muted)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    DiamondDivider(color: AppColors.accent)

                    // Form
                    VStack(spacing: AppSpacing.md) {
                        EloraTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $viewModel.email,
                            keyboardType: .emailAddress
                        )

                        EloraSecureField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $viewModel.password
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Sign In Button
                    Button(action: {
                        Task { await viewModel.signIn() }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("SIGN IN")
                        }
                    }
                    .buttonStyle(EloraPrimaryButton())
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, AppSpacing.lg)

                    // Guest
                    Button(action: {
                        Task { await viewModel.continueAsGuest() }
                    }) {
                        Text("CONTINUE AS GUEST")
                    }
                    .buttonStyle(EloraSecondaryButton())
                    .padding(.horizontal, AppSpacing.lg)

                    // Sign Up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.muted)

                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accent)
                    }
                    .padding(.top, AppSpacing.sm)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView(viewModel: viewModel, isPresented: $showSignUp)
        }
    }
}

// MARK: - Custom Text Fields

struct EloraTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.muted)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }
}

struct EloraSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.muted)
                .frame(width: 20)

            if showPassword {
                TextField(placeholder, text: $text)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
            }

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(AppColors.muted)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.line, lineWidth: 0.5)
        )
    }
}
