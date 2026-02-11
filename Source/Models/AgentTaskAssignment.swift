//
//  AgentTaskAssignment.swift
//  TaskLuid
//

import Foundation

struct AgentTaskAssignment: Codable, Identifiable {
    let id: Int
    let agentId: Int
    let taskId: Int
    let status: String
    let assignedAt: String
    let task: AgentTaskDetail?
    let agent: AgentSummary?
}

struct AgentTaskDetail: Codable {
    let id: Int
    let title: String
    let status: String
    let priority: String?
    let dueDate: String?
    let project: AgentProjectSummary?
    let author: AgentUserSummary?
}

struct AgentProjectSummary: Codable {
    let id: Int
    let name: String
}

struct AgentUserSummary: Codable {
    let userId: Int
    let username: String
}

struct AgentSummary: Codable {
    let id: Int
    let name: String
    let displayName: String
}
