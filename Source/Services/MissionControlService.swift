//
//  MissionControlService.swift
//  TaskLuid
//

import Foundation

@MainActor
class MissionControlService {
    static let shared = MissionControlService()
    private let client = APIClient.shared

    private init() {}

    func getAgents(organizationId: Int? = nil) async throws -> [Agent] {
        var params: [String: Any] = [:]
        if let organizationId {
            params["organizationId"] = organizationId
        }
        return try await client.get(APIEndpoint.agents, parameters: params)
    }

    func getAgentTasks(agentId: Int, status: String? = nil) async throws -> [AgentTaskAssignment] {
        var params: [String: Any] = [:]
        if let status {
            params["status"] = status
        }
        return try await client.get(APIEndpoint.agentTasks(agentId), parameters: params)
    }

    func getActivityFeed(organizationId: Int, limit: Int = 50) async throws -> [ActivityLog] {
        return try await client.get(APIEndpoint.activityFeed(organizationId), parameters: ["limit": limit])
    }

    func getTaskAgentAssignments(taskId: Int) async throws -> [TaskAgentAssignment] {
        return try await client.get(APIEndpoint.taskAgentAssignments(taskId))
    }

    func assignTaskToAgents(taskId: Int, agentIds: [Int]) async throws -> TaskAgentAssignmentsResponse {
        return try await client.post(APIEndpoint.taskAgentAssignments(taskId), parameters: ["agentIds": agentIds])
    }

    func unassignTaskFromAgent(taskId: Int, agentId: Int) async throws -> DeleteResponse {
        return try await client.delete(APIEndpoint.taskAgentAssignment(taskId, agentId: agentId))
    }

    func createAgent(name: String, displayName: String, role: String) async throws -> AgentCreateResponse {
        let params: [String: Any] = [
            "name": name,
            "displayName": displayName,
            "role": role
        ]
        return try await client.post(APIEndpoint.agents, parameters: params)
    }

    func deleteAgent(agentId: Int) async throws -> DeleteResponse {
        return try await client.delete(APIEndpoint.agent(agentId))
    }
}
