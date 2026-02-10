//
//  ProjectService.swift
//  TaskLuid
//

import Foundation

@MainActor
class ProjectService {
    static let shared = ProjectService()
    private let client = APIClient.shared

    private init() {}

    func getProjects(archived: Bool? = nil, favorites: Bool? = nil, userId: Int? = nil, status: String? = nil) async throws -> [Project] {
        var params: [String: Any] = [:]
        if let archived = archived { params["archived"] = archived }
        if let favorites = favorites { params["favorites"] = favorites }
        if let userId = userId { params["userId"] = userId }
        if let status = status { params["status"] = status }

        return try await client.get(APIEndpoint.projects, parameters: params)
    }

    func getProject(id: Int, userId: Int? = nil) async throws -> Project {
        var params: [String: Any] = [:]
        if let userId = userId { params["userId"] = userId }
        return try await client.get(APIEndpoint.project(id), parameters: params)
    }

    func createProject(name: String, description: String?) async throws -> Project {
        let params: [String: Any] = [
            "name": name,
            "description": description ?? ""
        ]
        return try await client.post(APIEndpoint.projects, parameters: params)
    }

    func getProjectStatuses(projectId: Int) async throws -> [ProjectStatus] {
        return try await client.get(APIEndpoint.projectStatuses(projectId))
    }
}
