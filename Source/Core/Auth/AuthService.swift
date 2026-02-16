//
//  AuthService.swift
//  TaskLuid
//

import Foundation

struct AuthTokens: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String
}

struct AuthStatusResponse: Codable {
    let isAuthenticated: Bool
    let user: User?
    let organizations: [Organization]?
    let activeOrganization: Organization?
}

struct LoginResponse: Codable {
    let success: Bool?
    let tokens: AuthTokens?
    let user: User?
    let organizations: [Organization]?
    let activeOrganization: Organization?
    let challenge: String?
    let session: String?
    let challengeParameters: [String: String]?
}

struct RegisterResponse: Codable {
    let success: Bool
    let userSub: String?
    let needsConfirmation: Bool?
    let message: String
}

struct ConfirmSignUpResponse: Codable {
    let success: Bool
    let message: String
}

enum AuthLoginResult {
    case authenticated(User)
    case challenge(AuthChallenge)
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case challengeRequired
    case tokenExpired
    case apiError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password."
        case .challengeRequired:
            return "Additional verification required."
        case .tokenExpired:
            return "Your session has expired. Please login again."
        case .apiError(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

@MainActor
class AuthService {
    static let shared = AuthService()

    private let client = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    func isAuthenticated() -> Bool {
        keychain.hasAccessToken()
    }

    func login(username: String, password: String) async throws -> AuthLoginResult {
        let params: [String: Any] = [
            "username": username,
            "password": password
        ]

        do {
            let response: LoginResponse = try await client.post(APIEndpoint.login, parameters: params, requiresAuth: false)

            if let challenge = response.challenge, let session = response.session {
                return .challenge(AuthChallenge(challenge: challenge, session: session, challengeParameters: response.challengeParameters))
            }

            guard let tokens = response.tokens else {
                throw AuthError.apiError("Missing authentication tokens.")
            }

            saveTokens(tokens)

            if let user = response.user {
                _ = keychain.saveUserId(String(user.userId))
                if let email = user.email {
                    _ = keychain.saveUserEmail(email)
                }
                if let activeOrg = response.activeOrganization?.id {
                    _ = keychain.saveActiveOrganizationId(String(activeOrg))
                } else {
                    let status = try await getAuthStatus()
                    if let activeOrg = status.activeOrganization?.id {
                        _ = keychain.saveActiveOrganizationId(String(activeOrg))
                    } else {
                        _ = keychain.saveActiveOrganizationId("")
                    }
                }
                return .authenticated(user)
            }

            let status = try await getAuthStatus()
            if let user = status.user {
                if let activeOrg = status.activeOrganization?.id {
                    _ = keychain.saveActiveOrganizationId(String(activeOrg))
                } else {
                    _ = keychain.saveActiveOrganizationId("")
                }
                return .authenticated(user)
            }

            throw AuthError.unknown
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func respondToChallenge(
        challengeName: String,
        session: String,
        challengeResponses: [String: String],
        username: String
    ) async throws -> AuthLoginResult {
        let params: [String: Any] = [
            "challengeName": challengeName,
            "session": session,
            "challengeResponses": challengeResponses,
            "username": username
        ]

        do {
            let response: LoginResponse = try await client.post(APIEndpoint.respondToChallenge, parameters: params, requiresAuth: false)

            if let challenge = response.challenge, let session = response.session {
                return .challenge(AuthChallenge(challenge: challenge, session: session, challengeParameters: response.challengeParameters))
            }

            guard let tokens = response.tokens else {
                throw AuthError.apiError("Missing authentication tokens.")
            }

            saveTokens(tokens)

            let status = try await getAuthStatus()
            if let user = status.user {
                return .authenticated(user)
            }

            throw AuthError.unknown
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func register(
        username: String,
        password: String,
        email: String,
        phone: String? = nil,
        birthdate: String? = nil,
        fullName: String? = nil
    ) async throws -> RegisterResponse {
        let params: [String: Any] = [
            "username": username,
            "password": password,
            "email": email,
            "phone": phone ?? "",
            "birthdate": birthdate ?? "",
            "fullName": fullName ?? ""
        ]

        do {
            return try await client.post(APIEndpoint.register, parameters: params, requiresAuth: false)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func confirmSignUp(username: String, confirmationCode: String) async throws -> ConfirmSignUpResponse {
        let params: [String: Any] = [
            "username": username,
            "confirmationCode": confirmationCode
        ]

        do {
            return try await client.post(APIEndpoint.confirmSignUp, parameters: params, requiresAuth: false)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws -> ConfirmSignUpResponse {
        let params: [String: Any] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]

        do {
            return try await client.post(APIEndpoint.changePassword, parameters: params, requiresAuth: true)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func logout() async {
        do {
            let _: ConfirmSignUpResponse = try await client.post(APIEndpoint.logout, requiresAuth: true)
        } catch {
            // Ignore errors and clear local tokens
        }
        keychain.clearAll()
    }

    func getAuthStatus() async throws -> AuthStatusResponse {
        try await client.get(APIEndpoint.authStatus, requiresAuth: true)
    }

    private func saveTokens(_ tokens: AuthTokens) {
        _ = keychain.saveAccessToken(tokens.accessToken)
        _ = keychain.saveIdToken(tokens.idToken)
        _ = keychain.saveRefreshToken(tokens.refreshToken)
    }

    private func mapAPIError(_ error: APIError) -> AuthError {
        switch error {
        case .unauthorized:
            return .invalidCredentials
        case .serverError(let message):
            return .apiError(message)
        default:
            return .apiError(error.localizedDescription)
        }
    }
}
