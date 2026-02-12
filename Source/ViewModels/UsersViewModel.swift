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
    private var hasLoaded = false

    func loadUsers() async {
        if hasLoaded && !users.isEmpty {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if AppConfig.useMockData {
            users = MockData.users
            return
        }

        do {
            users = try await userService.getUsers()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
