//
//  AppConfig.swift
//  TaskLuid
//
//  Application configuration and API endpoints
//

import Foundation

enum AppConfig {
    // MARK: - API Configuration

    static let useMockData = true

    static var apiBaseURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"
        #else
        return "http://192.168.8.39:8000"
        #endif
    }

    static let apiTimeout: TimeInterval = 30

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static func apiURL(for endpoint: String) -> String {
        let cleanEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        return "\(apiBaseURL)\(cleanEndpoint)"
    }
}

// MARK: - API Endpoints

enum APIEndpoint {
    // MARK: - Health
    static let health = "/"

    // MARK: - Authentication
    static let authStatus = "/auth/status"
    static let login = "/auth/login"
    static let register = "/auth/register"
    static let confirmSignUp = "/auth/confirm-signup"
    static let respondToChallenge = "/auth/respond-to-challenge"
    static let logout = "/auth/logout"

    // MARK: - Projects
    static let projects = "/projects"
    static func project(_ id: Int) -> String {
        "/projects/\(id)"
    }
    static func projectStatuses(_ projectId: Int) -> String {
        "/projects/\(projectId)/statuses"
    }

    // MARK: - Tasks
    static let tasks = "/tasks"
    static func task(_ id: Int) -> String {
        "/tasks/\(id)"
    }
    static func taskStatus(_ id: Int) -> String {
        "/tasks/\(id)/status"
    }
    static func tasksByUser(_ userId: Int) -> String {
        "/tasks/user/\(userId)"
    }

    // MARK: - Users
    static let users = "/users"
    static func userByCognitoId(_ cognitoId: String) -> String {
        "/users/\(cognitoId)"
    }

    // MARK: - Teams
    static let teams = "/teams"

    // MARK: - Search
    static let search = "/search"
}
