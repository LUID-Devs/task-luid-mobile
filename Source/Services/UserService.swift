//
//  UserService.swift
//  TaskLuid
//

import Foundation

@MainActor
class UserService {
    static let shared = UserService()
    private let client = APIClient.shared

    private init() {}

    func getUsers() async throws -> [User] {
        return try await client.get(APIEndpoint.users)
    }

    func getUserByCognitoId(_ cognitoId: String) async throws -> User {
        return try await client.get(APIEndpoint.userByCognitoId(cognitoId))
    }

    func updateProfile(userId: Int, username: String?, email: String?) async throws -> User {
        var params: [String: Any] = [:]
        if let username {
            params["username"] = username
        }
        if let email {
            params["email"] = email
        }
        let response: UserProfileResponse = try await client.put(
            APIEndpoint.userProfile(userId),
            parameters: params
        )
        guard let user = response.user else {
            throw APIError.noData
        }
        return user
    }
}

private struct UserProfileResponse: Codable {
    let success: Bool?
    let message: String?
    let user: User?
}
