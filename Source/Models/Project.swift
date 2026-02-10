//
//  Project.swift
//  TaskLuid
//

import Foundation

struct Project: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let archived: Bool?
    let archivedAt: String?
    let isFavorited: Bool?
    let statistics: ProjectStatistics?
    let teamMembers: [ProjectMember]?
    let taskCount: Int?
}

struct ProjectStatistics: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let inProgressTasks: Int
    let todoTasks: Int
    let progress: Double
    let memberCount: Int
    let status: String
}

struct ProjectMember: Codable, Identifiable {
    let userId: Int
    let username: String
    let profilePictureUrl: String?

    var id: Int { userId }
}
