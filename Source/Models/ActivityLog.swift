//
//  ActivityLog.swift
//  TaskLuid
//

import Foundation

struct ActivityLog: Codable, Identifiable {
    let id: Int
    let agentId: Int
    let action: String
    let taskId: Int?
    let details: [String: JSONValue]?
    let createdAt: String
    let agent: ActivityAgent
    let task: ActivityTask?
}

struct ActivityAgent: Codable {
    let id: Int
    let name: String
    let displayName: String
    let role: String
}

struct ActivityTask: Codable {
    let id: Int
    let title: String
}
