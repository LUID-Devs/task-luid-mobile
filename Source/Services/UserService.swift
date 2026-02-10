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
}
