//
//  TeamService.swift
//  TaskLuid
//

import Foundation

@MainActor
class TeamService {
    static let shared = TeamService()
    private let client = APIClient.shared

    private init() {}

    func getTeams() async throws -> [Team] {
        return try await client.get(APIEndpoint.teams, requiresAuth: false)
    }
}
