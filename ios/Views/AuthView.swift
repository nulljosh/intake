import AuthenticationServices
import SwiftUI

struct AuthView: View {
    var authService: AuthService

    @State private var tab: Tab = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var errorMessage: String?
    @State private var successMessage: String?

    enum Tab { case signIn, register, reset }

    private var canSubmit: Bool { !loading && !email.isEmpty && (tab == .reset || !password.isEmpty) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // One column on the page, no card: 24 pt margins, 8 pt rhythm, every control a 48 pt capsule.
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image("Mark") // the stethoscope from the app icon (brand/mark.svg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(.bottom, 8)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text("Machaon")
                        .font(.largeTitle.weight(.semibold))

                    Text("Track what you take, and what it does")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if tab != .reset {
                    Picker("", selection: $tab) {
                        Text("Sign in").tag(Tab.signIn)
                        Text("Register").tag(Tab.register)
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
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
                        .modifier(CapsuleField())

                    if tab != .reset {
                        SecureField("Password", text: $password)
                            .textContentType(tab == .signIn ? .password : .newPassword)
                            .modifier(CapsuleField())
                    }

                    if tab == .signIn {
                        HStack {
                            Button("Forgot password?") {
                                errorMessage = nil
                                successMessage = nil
                                tab = .reset
                            }
                            .font(.subheadline)
                            .frame(minHeight: 44)
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
                            .font(.subheadline)
                            .frame(minHeight: 44)
                            Spacer()
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let success = successMessage {
                    Text(success)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack(spacing: 8) {
                        if loading { ProgressView().tint(.white) }
                        Text(buttonLabel)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    // Disabled reads as grey and quiet, not a washed-out blue with a label you can't read.
                    .foregroundStyle(canSubmit ? Color.white : Color.secondary)
                    .background(canSubmit ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)

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
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 48)
                        .clipShape(Capsule())
                    }

                    Button {
                        Task {
                            loading = true
                            defer { loading = false }
                            do { try await authService.signInWithGoogle() }
                            catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin { }
                            catch { errorMessage = error.localizedDescription }
                        }
                    } label: {
                        // Google's own button: white with a grey outline in light mode, near-black in dark,
                        // the four-colour G on the left. Same height and capsule as the Apple button above.
                        HStack(spacing: 10) {
                            Image("GoogleG").resizable().frame(width: 18, height: 18).accessibilityHidden(true)
                            Text("Sign in with Google").font(.system(size: 17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.89) : Color(white: 0.12))
                        .background(colorScheme == .dark ? Color(white: 0.075) : .white, in: Capsule())
                        .overlay(Capsule().stroke(colorScheme == .dark ? Color(white: 0.56) : Color(white: 0.46), lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 400)
            .padding(.horizontal, 24)

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

/// A 48 pt capsule text field, the same height and shape as every button on the screen.
private struct CapsuleField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(Color.secondary.opacity(0.12), in: Capsule())
    }
}
