//
//  AIService.swift
//  TaskLuid
//

import Foundation

@MainActor
class AIService {
    static let shared = AIService()
    private let client = APIClient.shared

    private init() {}

    func parseTask(text: String, teamMembers: [String]) async throws -> AIParseTaskResponse {
        let params: [String: Any] = [
            "text": text,
            "teamMembers": teamMembers
        ]
        return try await client.post(APIEndpoint.aiParseTask, parameters: params)
    }
}
