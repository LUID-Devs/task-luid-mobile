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
        status: TaskStatus?
    ) async throws -> TaskItem {
        var params: [String: Any] = [
            "title": title,
            "projectId": projectId
        ]
        if let description = description { params["description"] = description }
        if let priority = priority { params["priority"] = priority.rawValue }
        if let status = status { params["status"] = status.rawValue }
        if let userId = keychain.getUserId(), let authorUserId = Int(userId) {
            params["authorUserId"] = authorUserId
            params["assignedUserId"] = authorUserId
        }

        return try await client.post(APIEndpoint.tasks, parameters: params)
    }

    func updateTaskStatus(taskId: Int, status: TaskStatus) async throws -> TaskItem {
        return try await client.patch(APIEndpoint.taskStatus(taskId), parameters: ["status": status.rawValue])
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
        assignedUserId: Int?
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

        return try await client.put(APIEndpoint.task(taskId), parameters: params)
    }
}
