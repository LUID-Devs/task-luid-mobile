//
//  APIClient.swift
//  TaskLuid
//

import Foundation
import os.log

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case networkError(Error)
    case unknown

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Your session has expired. Please login again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

@MainActor
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: String
    private let keychainManager: KeychainManager
    private let logger = OSLog(subsystem: "com.luid.taskluid", category: "APIClient")

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.apiTimeout
        configuration.timeoutIntervalForResource = 60

        self.session = URLSession(configuration: configuration)
        self.baseURL = AppConfig.apiBaseURL
        self.keychainManager = KeychainManager.shared

        NSLog("⚙️ APIClient initialized: \(baseURL)")
    }

    func get<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: .get, parameters: parameters, requiresAuth: requiresAuth)
    }

    func post<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: .post, parameters: parameters, requiresAuth: requiresAuth)
    }

    func put<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: .put, parameters: parameters, requiresAuth: requiresAuth)
    }

    func patch<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: .patch, parameters: parameters, requiresAuth: requiresAuth)
    }

    func delete<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: .delete, parameters: parameters, requiresAuth: requiresAuth)
    }

    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool
    ) async throws -> T {
        var urlString = baseURL + endpoint

        if method == .get, let parameters = parameters {
            var components = URLComponents(string: urlString)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = components?.url?.absoluteString ?? urlString
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let token = keychainManager.getAccessToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            if let idToken = keychainManager.getIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "X-ID-Token")
            }
        }

        if method != .get, let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        do {
            os_log("🌐 Request: %{public}@ %{public}@", log: logger, type: .info, method.rawValue, urlString)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }

            if httpResponse.statusCode == 401 {
                if requiresAuth {
                    keychainManager.clearAll()
                }
                throw APIError.unauthorized
            }

            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error ?? errorResponse.message ?? "Request failed")
                }
                throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                if let raw = String(data: data, encoding: .utf8) {
                    NSLog("❌ Decoding failed. Status: \(httpResponse.statusCode). Raw response: \(raw)")
                } else {
                    NSLog("❌ Decoding failed. Status: \(httpResponse.statusCode). Response size: \(data.count) bytes")
                }
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

struct ErrorResponse: Codable {
    let error: String?
    let message: String?
    let code: String?
    let details: [String: String]?
}

struct SuccessResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}
