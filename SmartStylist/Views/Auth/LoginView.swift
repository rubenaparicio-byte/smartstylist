import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ZStack {
            Color.dsDeepSlate.ignoresSafeArea()

            // Ambient glow behind the wordmark
            RadialGradient(
                colors: [Color.dsAccentGold.opacity(0.13), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                wordmark
                Spacer()
                authButtons
                    .padding(.horizontal, 28)
                privacyNote
                    .padding(.bottom, 40)
            }
        }
        .alert("Sign-in Error", isPresented: Binding(
            get: { auth.loginError != nil },
            set: { _ in auth.loginError = nil }
        )) {
            Button("OK", role: .cancel) { auth.loginError = nil }
        } message: {
            Text(auth.loginError ?? "")
        }
    }

    // ── Wordmark ──────────────────────────────────────────────────────────────

    private var wordmark: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .thin))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.dsAccentGold)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 10) {
                Text("SmartStylist")
                    .font(.dsLargeTitle)
                    .foregroundStyle(Color.dsTextPrimary)
                    .tracking(3)

                Text("Your AI-powered personal stylist")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)
            }
        }
    }

    // ── Auth buttons ──────────────────────────────────────────────────────────

    private var authButtons: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization): auth.handleAuthorization(authorization)
                case .failure(let error):         auth.handleError(error)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            orDivider

            googleSignInButton
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.dsTextTertiary.opacity(0.3))
                .frame(height: 0.5)
            Text("or")
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
            Rectangle()
                .fill(Color.dsTextTertiary.opacity(0.3))
                .frame(height: 0.5)
        }
    }

    // TODO: Wire up GoogleSignIn-iOS SDK once OAuth 2.0 credentials are
    // configured in Google Cloud Console and the reversed client ID is
    // registered under GIDClientID in project.yml info.properties.
    private var googleSignInButton: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                googleGLogo

                Text("Sign in with Google")
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.dsTextTertiary.opacity(0.22), lineWidth: 0.5)
            )
            .overlay(alignment: .topTrailing) {
                comingSoonBadge
                    .offset(x: -10, y: -8)
            }
        }
        .disabled(true)
    }

    private var googleGLogo: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
            Text("G")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
        }
    }

    private var comingSoonBadge: some View {
        Text("Coming soon")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color.dsAccentGold.opacity(0.8))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.dsAccentGold.opacity(0.12))
            .clipShape(Capsule())
    }

    // ── Privacy note ──────────────────────────────────────────────────────────

    private var privacyNote: some View {
        Text("By continuing, you agree to our **Terms of Service** and **Privacy Policy**.")
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .padding(.top, 20)
    }
}
