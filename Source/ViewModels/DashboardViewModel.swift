//
//  DashboardViewModel.swift
//  TaskLuid
//

import Foundation

struct DashboardSummary {
    let projectCount: Int
    let taskCount: Int
    let completedCount: Int
    let inProgressCount: Int
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary? = nil
    @Published var recentProjects: [Project] = []
    @Published var recentTasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    private var lastLoadedUserId: Int? = nil

    private let projectService = ProjectService.shared
    private let taskService = TaskService.shared

    func loadDashboard(userId: Int) async {
        if isLoading || lastLoadedUserId == userId {
            return
        }
        isLoading = true
        errorMessage = nil
        lastLoadedUserId = userId
        defer { isLoading = false }

        if AppConfig.useMockData {
            let projects = MockData.projects
            let tasks = MockData.tasks.filter { task in
                task.assignedUserId == userId || task.authorUserId == userId
            }
            let completed = tasks.filter { $0.status == .completed }.count
            let inProgress = tasks.filter { $0.status == .workInProgress }.count
            summary = DashboardSummary(
                projectCount: projects.count,
                taskCount: tasks.count,
                completedCount: completed,
                inProgressCount: inProgress
            )
            recentProjects = Array(projects.prefix(5))
            recentTasks = Array(tasks.prefix(5))
            return
        }

        do {
            async let projectsTask = projectService.getProjects(userId: userId)
            async let tasksTask = taskService.getTasksByUser(userId: userId)

            let projects = try await projectsTask
            let tasks = try await tasksTask

            let completed = tasks.filter { $0.status == .completed }.count
            let inProgress = tasks.filter { $0.status == .workInProgress }.count

            summary = DashboardSummary(
                projectCount: projects.count,
                taskCount: tasks.count,
                completedCount: completed,
                inProgressCount: inProgress
            )
            recentProjects = Array(projects.prefix(5))
            recentTasks = Array(tasks.prefix(5))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
