//
//  TaskItem.swift
//  TaskLuid
//

import Foundation

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case toDo = "To Do"
    case workInProgress = "Work In Progress"
    case underReview = "Under Review"
    case completed = "Completed"

    var id: String { rawValue }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case urgent = "Urgent"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case backlog = "Backlog"

    var id: String { rawValue }
}

enum TaskType: String, Codable, CaseIterable, Identifiable {
    case feature = "Feature"
    case bug = "Bug"
    case chore = "Chore"

    var id: String { rawValue }
}

struct TaskItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String?
    let descriptionImageUrl: String?
    let status: TaskStatus?
    let priority: TaskPriority?
    let taskType: TaskType?
    let tags: String?
    let startDate: String?
    let dueDate: String?
    let points: Int?
    let projectId: Int
    let authorUserId: Int?
    let assignedUserId: Int?

    let author: User?
    let assignee: User?
    let comments: [Comment]?
    let attachments: [Attachment]?

    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
