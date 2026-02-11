//
//  ProjectsViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let projectService = ProjectService.shared
    private var hasLoadedOnce = false

    func loadProjects() async {
        if isLoading || hasLoadedOnce {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            projects = MockData.projects
            hasLoadedOnce = true
            return
        }

        do {
            projects = try await projectService.getProjects()
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createProject(name: String, description: String?) async -> Project? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            let nextId = (projects.map(\.id).max() ?? 0) + 1
            let project = Project(
                id: nextId,
                name: name,
                description: description,
                startDate: nil,
                endDate: nil,
                archived: false,
                archivedAt: nil,
                isFavorited: false,
                statistics: nil,
                teamMembers: [],
                taskCount: 0
            )
            projects.insert(project, at: 0)
            return project
        }

        do {
            let project = try await projectService.createProject(name: name, description: description)
            projects.insert(project, at: 0)
            return project
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
