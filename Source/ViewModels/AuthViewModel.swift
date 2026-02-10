//
//  AuthViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var user: User? = nil
    @Published var errorMessage: String? = nil
    @Published var challenge: AuthChallenge? = nil
    @Published var pendingUsername: String? = nil

    private let authService = AuthService.shared

    init() {
        Task { await restoreSession() }
    }

    func restoreSession() async {
        guard authService.isAuthenticated() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let status = try await authService.getAuthStatus()
            if let user = status.user {
                self.user = user
                self.isAuthenticated = true
            } else {
                self.isAuthenticated = false
            }
        } catch {
            self.isAuthenticated = false
        }
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await authService.login(username: username, password: password)
            switch result {
            case .authenticated(let user):
                self.user = user
                self.isAuthenticated = true
                self.challenge = nil
                self.pendingUsername = nil
            case .challenge(let challenge):
                self.challenge = challenge
                self.pendingUsername = username
            }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func respondToChallenge(code: String) async {
        guard let challenge = challenge, let username = pendingUsername else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let challengeResponses: [String: String] = [
            "USERNAME": username,
            "SMS_MFA_CODE": code,
            "SOFTWARE_TOKEN_MFA_CODE": code
        ]

        do {
            let result = try await authService.respondToChallenge(
                challengeName: challenge.challenge,
                session: challenge.session,
                challengeResponses: challengeResponses,
                username: username
            )
            switch result {
            case .authenticated(let user):
                self.user = user
                self.isAuthenticated = true
                self.challenge = nil
                self.pendingUsername = nil
            case .challenge(let challenge):
                self.challenge = challenge
            }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func register(username: String, email: String, password: String) async -> RegisterResponse? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await authService.register(username: username, password: password, email: email, fullName: username)
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }

    func confirmSignUp(username: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.confirmSignUp(username: username, confirmationCode: code)
            return true
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func logout() async {
        isLoading = true
        await authService.logout()
        self.isAuthenticated = false
        self.user = nil
        self.challenge = nil
        self.pendingUsername = nil
        self.isLoading = false
    }
}
