//
//  TasksViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let taskService = TaskService.shared

    func loadTasks(projectId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            tasks = MockData.tasks.filter { $0.projectId == projectId }
            return
        }

        do {
            tasks = try await taskService.getTasks(projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTasksByUser(userId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            tasks = MockData.tasks.filter { task in
                task.assignedUserId == userId || task.authorUserId == userId
            }
            return
        }

        do {
            tasks = try await taskService.getTasksByUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTask(
        title: String,
        description: String?,
        projectId: Int,
        priority: TaskPriority?,
        status: TaskStatus?
    ) async -> TaskItem? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            let nextId = (tasks.map(\.id).max() ?? 0) + 1
            let author = MockData.users.first
            let assignee = MockData.users.dropFirst().first
            let task = TaskItem(
                id: nextId,
                title: title,
                description: description,
                descriptionImageUrl: nil,
                status: status ?? .toDo,
                priority: priority ?? .medium,
                taskType: .feature,
                tags: nil,
                startDate: nil,
                dueDate: "2026-02-20",
                points: 3,
                projectId: projectId,
                authorUserId: author?.userId,
                assignedUserId: assignee?.userId,
                author: author,
                assignee: assignee,
                comments: [],
                attachments: []
            )
            tasks.insert(task, at: 0)
            return task
        }

        do {
            let task = try await taskService.createTask(
                title: title,
                description: description,
                projectId: projectId,
                priority: priority,
                status: status
            )
            tasks.insert(task, at: 0)
            return task
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
