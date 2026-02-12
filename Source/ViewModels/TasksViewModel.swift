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
    @Published var debugResponse: String? = nil

    private let taskService = TaskService.shared
    private var hasLoadedOnce = false
    private var lastLoadedUserId: Int? = nil
    private var lastLoadedProjectId: Int? = nil
    private var lastUserLoadAt: Date? = nil
    private let minRefreshInterval: TimeInterval = 5

    func loadTasks(projectId: Int, force: Bool = false) async {
        if !force, (isLoading || (lastLoadedProjectId == projectId && !tasks.isEmpty)) {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            tasks = MockData.tasks.filter { $0.projectId == projectId }
            hasLoadedOnce = true
            return
        }

        do {
            tasks = try await taskService.getTasks(projectId: projectId)
            lastLoadedProjectId = projectId
            hasLoadedOnce = true
        } catch {
            if isCancellation(error) {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func loadTasksByUser(userId: Int, force: Bool = false) async {
        if !force {
            if isLoading || (lastLoadedUserId == userId && !tasks.isEmpty) {
                return
            }
            if let lastUserLoadAt, Date().timeIntervalSince(lastUserLoadAt) < minRefreshInterval {
                return
            }
        }
        isLoading = true
        errorMessage = nil
        debugResponse = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            tasks = MockData.tasks.filter { task in
                task.assignedUserId == userId || task.authorUserId == userId
            }
            hasLoadedOnce = true
            debugResponse = "mock:\(tasks.count)"
            return
        }

        do {
            tasks = try await taskService.getTasksByUser(userId: userId)
            lastLoadedUserId = userId
            lastUserLoadAt = Date()
            hasLoadedOnce = true
            debugResponse = "loaded:\(tasks.count)"
        } catch {
            if isCancellation(error) {
                debugResponse = "cancelled"
                return
            }
            errorMessage = error.localizedDescription
            debugResponse = "error:\(error.localizedDescription)"
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if let apiError = error as? APIError,
           case .networkError(let underlying) = apiError,
           let urlError = underlying as? URLError,
           urlError.code == .cancelled {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        return false
    }

    func createTask(
        title: String,
        description: String?,
        projectId: Int,
        priority: TaskPriority?,
        status: TaskStatus?,
        tags: String? = nil,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        points: Int? = nil,
        taskType: TaskType? = nil,
        assignedUserId: Int? = nil,
        authorUserId: Int? = nil
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
                taskType: taskType ?? .feature,
                tags: tags,
                startDate: isoString(from: startDate),
                dueDate: isoString(from: dueDate) ?? "2026-02-20",
                points: points,
                projectId: projectId,
                authorUserId: author?.userId,
                assignedUserId: assignedUserId ?? assignee?.userId,
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
                status: status,
                tags: tags,
                startDate: isoString(from: startDate),
                dueDate: isoString(from: dueDate),
                points: points,
                taskType: taskType,
                authorUserId: authorUserId,
                assignedUserId: assignedUserId
            )
            tasks.insert(task, at: 0)
            return task
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func isoString(from date: Date?) -> String? {
        guard let date else { return nil }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        let normalized = calendar.date(from: components) ?? date

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        iso.timeZone = TimeZone.current
        return iso.string(from: normalized)
    }

    func upsertTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }
    }
}
