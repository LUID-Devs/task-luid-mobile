//
//  TimelineViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let taskService = TaskService.shared

    func loadTasks(userId: Int) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await taskService.getTasksByUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
