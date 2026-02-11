//
//  TaskAgentAssignment.swift
//  TaskLuid
//

import Foundation

struct TaskAgentAssignment: Codable, Identifiable {
    let id: Int
    let agentId: Int
    let taskId: Int
    let status: String
    let assignedAt: String
    let agent: AgentSummary?
}
