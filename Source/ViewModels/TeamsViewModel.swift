//
//  TeamsViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let teamService = TeamService.shared

    func loadTeams() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            teams = MockData.teams
            return
        }

        do {
            teams = try await teamService.getTeams()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
