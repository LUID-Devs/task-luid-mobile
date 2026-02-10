//
//  TaskService.swift
//  TaskLuid
//

import Foundation

@MainActor
class TaskService {
    static let shared = TaskService()
    private let client = APIClient.shared

    private init() {}

    func getTasks(projectId: Int) async throws -> [TaskItem] {
        return try await client.get(APIEndpoint.tasks, parameters: ["projectId": projectId])
    }

    func getTask(id: Int) async throws -> TaskItem {
        return try await client.get(APIEndpoint.task(id))
    }

    func getTasksByUser(userId: Int) async throws -> [TaskItem] {
        return try await client.get(APIEndpoint.tasksByUser(userId))
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

        return try await client.post(APIEndpoint.tasks, parameters: params)
    }

    func updateTaskStatus(taskId: Int, status: TaskStatus) async throws -> TaskItem {
        return try await client.patch(APIEndpoint.taskStatus(taskId), parameters: ["status": status.rawValue])
    }
}
