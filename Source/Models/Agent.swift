//
//  Agent.swift
//  TaskLuid
//

import Foundation

struct Agent: Codable, Identifiable {
    let id: Int
    let name: String
    let displayName: String
    let role: String
    let status: String
    let lastHeartbeat: String?
    let currentTaskId: Int?
    let currentTask: AgentTaskSummary?
    let count: AgentCount?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
        case role
        case status
        case lastHeartbeat
        case currentTaskId
        case currentTask
        case count = "_count"
    }
}

struct AgentTaskSummary: Codable {
    let id: Int
    let title: String
    let status: String
}

struct AgentCount: Codable {
    let assignedTasks: Int?
    let notifications: Int?
}

struct AgentCreateResponse: Codable {
    let id: Int
    let name: String
    let displayName: String
    let role: String
    let organizationId: Int?
    let apiKey: String?
    let message: String?
}

struct DeleteResponse: Codable {
    let message: String?
}

struct TaskAgentAssignmentsResponse: Codable {
    let success: Bool?
    let data: [TaskAgentAssignment]?
    let message: String?
}
