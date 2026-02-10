//
//  UsersViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let userService = UserService.shared

    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            users = MockData.users
            return
        }

        do {
            users = try await userService.getUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
