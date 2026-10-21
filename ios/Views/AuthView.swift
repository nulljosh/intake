import AuthenticationServices
import SwiftUI

struct AuthView: View {
    var authService: AuthService

    @State private var tab: Tab = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    enum Tab { case signIn, register, reset }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.tint)

                    Text("Machaon")
                        .font(.title2.weight(.semibold))

                    Text("Health tracker")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if tab != .reset {
                    Picker("", selection: $tab) {
                        Text("Sign in").tag(Tab.signIn)
                        Text("Register").tag(Tab.register)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tab) { _, _ in
                        errorMessage = nil
                        successMessage = nil
                    }
                } else {
                    HStack {
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    if tab != .reset {
                        SecureField("Password", text: $password)
                            .textContentType(tab == .signIn ? .password : .newPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    if tab == .signIn {
                        HStack {
                            Button("Forgot password?") {
                                errorMessage = nil
                                successMessage = nil
                                tab = .reset
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }

                    if tab == .reset {
                        HStack {
                            Button("Back to sign in") {
                                errorMessage = nil
                                successMessage = nil
                                tab = .signIn
                            }
                            .font(.caption)
                            .foregroundStyle(.tint)
                            Spacer()
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let success = successMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if loading { ProgressView() }
                        Text(buttonLabel)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading || email.isEmpty || (tab != .reset && password.isEmpty))

                if tab == .signIn {
                    Divider()

                    if appleSignInEnabled {
                        SignInWithAppleButton(.signIn) { request in
                            authService.prepareAppleRequest(request)
                        } onCompletion: { result in
                            Task {
                                loading = true
                                defer { loading = false }
                                do { try await authService.signInWithApple(result: result) }
                                // A dismissed sheet is not an error. A device with no Apple ID signed in (typical
                                // of a review device) used to surface Apple's raw error text.
                                catch let error as ASAuthorizationError where error.code == .canceled { }
                                catch is ASAuthorizationError {
                                    errorMessage = "Sign in with Apple isn't available on this device right now. Use email or Google instead."
                                }
                                catch { errorMessage = error.localizedDescription }
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                    }

                    Button {
                        Task {
                            loading = true
                            defer { loading = false }
                            do { try await authService.signInWithGoogle() }
                            catch { errorMessage = error.localizedDescription }
                        }
                    } label: {
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var buttonLabel: String {
        switch tab {
        case .signIn: return "Sign in"
        case .register: return "Create account"
        case .reset: return "Send reset email"
        }
    }

    private func submit() async {
        guard !loading else { return }
        errorMessage = nil
        successMessage = nil
        loading = true
        defer { loading = false }

        do {
            switch tab {
            case .signIn:
                try await authService.signIn(email: email, password: password)
            case .register:
                try await authService.signUp(email: email, password: password)
                successMessage = "Check your email to confirm your account"
            case .reset:
                try await authService.resetPassword(email: email)
                successMessage = "Check your email for a reset link"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
