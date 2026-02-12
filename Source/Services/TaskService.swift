//
//  TaskService.swift
//  TaskLuid
//

import Foundation

@MainActor
class TaskService {
    static let shared = TaskService()
    private let client = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    func getTasks(projectId: Int) async throws -> [TaskItem] {
        return try await client.get(APIEndpoint.tasks, parameters: ["projectId": projectId])
    }

    func getTask(id: Int) async throws -> TaskItem {
        return try await client.get(APIEndpoint.task(id))
    }

    func getTasksByUser(userId: Int) async throws -> [TaskItem] {
        let tasks: [TaskItem] = try await client.get(APIEndpoint.tasksByUser(userId))
        NSLog("🧭 Tasks for user \(userId): \(tasks.count)")
        return tasks
    }

    func createTask(
        title: String,
        description: String?,
        projectId: Int,
        priority: TaskPriority?,
        status: TaskStatus?,
        tags: String? = nil,
        startDate: String? = nil,
        dueDate: String? = nil,
        points: Int? = nil,
        taskType: TaskType? = nil,
        authorUserId: Int? = nil,
        assignedUserId: Int? = nil
    ) async throws -> TaskItem {
        var params: [String: Any] = [
            "title": title,
            "projectId": projectId
        ]
        if let description = description { params["description"] = description }
        if let priority = priority { params["priority"] = priority.rawValue }
        if let status = status { params["status"] = status.rawValue }
        if let tags { params["tags"] = tags }
        if let startDate { params["startDate"] = startDate }
        if let dueDate { params["dueDate"] = dueDate }
        if let points { params["points"] = points }
        if let taskType { params["taskType"] = taskType.rawValue }

        if let authorUserId {
            params["authorUserId"] = authorUserId
        }
        if let assignedUserId {
            params["assignedUserId"] = assignedUserId
        }
        if authorUserId == nil || assignedUserId == nil,
           let userId = keychain.getUserId(),
           let fallbackUserId = Int(userId) {
            params["authorUserId"] = params["authorUserId"] ?? fallbackUserId
            params["assignedUserId"] = params["assignedUserId"] ?? fallbackUserId
        }

        return try await client.post(APIEndpoint.tasks, parameters: params)
    }

    func updateTaskStatus(taskId: Int, status: TaskStatus) async throws -> TaskItem {
        return try await client.patch(APIEndpoint.taskStatus(taskId), parameters: ["status": status.rawValue])
    }

    func updateTaskStatus(taskId: Int, statusName: String) async throws -> TaskItem {
        return try await client.patch(APIEndpoint.taskStatus(taskId), parameters: ["status": statusName])
    }

    func updateTask(
        taskId: Int,
        title: String,
        description: String?,
        status: String?,
        priority: TaskPriority?,
        tags: String?,
        startDate: String?,
        dueDate: String?,
        points: Int?,
        assignedUserId: Int?,
        projectId: Int? = nil
    ) async throws -> TaskItem {
        var params: [String: Any] = [
            "title": title
        ]
        if let description { params["description"] = description }
        if let status { params["status"] = status }
        if let priority { params["priority"] = priority.rawValue }
        if let tags { params["tags"] = tags }
        if let startDate { params["startDate"] = startDate }
        if let dueDate { params["dueDate"] = dueDate }
        if let points { params["points"] = points }
        if let assignedUserId { params["assignedUserId"] = assignedUserId }
        if let projectId { params["projectId"] = projectId }

        return try await client.put(APIEndpoint.task(taskId), parameters: params)
    }

    func deleteTask(taskId: Int) async throws -> DeleteResponse {
        return try await client.delete(APIEndpoint.task(taskId))
    }
}
