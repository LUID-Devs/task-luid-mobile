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

    func createProjectStatus(projectId: Int, name: String, color: String? = nil) async throws -> ProjectStatus {
        var params: [String: Any] = ["name": name]
        if let color { params["color"] = color }
        return try await client.post(APIEndpoint.projectStatuses(projectId), parameters: params)
    }

    func updateProjectStatus(projectId: Int, statusId: Int, name: String? = nil, color: String? = nil, order: Int? = nil) async throws -> ProjectStatus {
        var params: [String: Any] = [:]
        if let name { params["name"] = name }
        if let color { params["color"] = color }
        if let order { params["order"] = order }
        return try await client.put(APIEndpoint.projectStatus(projectId, statusId: statusId), parameters: params)
    }

    func deleteProjectStatus(projectId: Int, statusId: Int, moveTasksTo: String? = nil) async throws -> DeleteResponse {
        var params: [String: Any] = [:]
        if let moveTasksTo { params["moveTasksTo"] = moveTasksTo }
        return try await client.delete(APIEndpoint.projectStatus(projectId, statusId: statusId), parameters: params)
    }

    func reorderProjectStatuses(projectId: Int, statusIds: [Int]) async throws -> [ProjectStatus] {
        return try await client.post(APIEndpoint.projectStatusesReorder(projectId), parameters: ["statusIds": statusIds])
    }
}
