import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(AppColors.text)
                                .font(.system(size: 18))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.text)

                        Text("Join the ELORA community")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.muted)
                    }

                    DiamondDivider(color: AppColors.accent)

                    // Form
                    VStack(spacing: AppSpacing.md) {
                        EloraTextField(
                            icon: "person",
                            placeholder: "Display Name (optional)",
                            text: $viewModel.displayName
                        )

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

                        EloraSecureField(
                            icon: "lock.shield",
                            placeholder: "Confirm Password",
                            text: $viewModel.confirmPassword
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

                    // Sign Up Button
                    Button(action: {
                        Task {
                            await viewModel.signUp()
                            if viewModel.isAuthenticated {
                                isPresented = false
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("CREATE ACCOUNT")
                        }
                    }
                    .buttonStyle(EloraPrimaryButton())
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
