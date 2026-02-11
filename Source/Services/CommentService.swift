//
//  CommentService.swift
//  TaskLuid
//

import Foundation

@MainActor
class CommentService {
    static let shared = CommentService()
    private let client = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    func getTaskComments(taskId: Int) async throws -> [Comment] {
        return try await client.get(APIEndpoint.taskComments(taskId))
    }

    func createComment(taskId: Int, text: String) async throws -> Comment {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        return try await client.post(APIEndpoint.taskComments(taskId), parameters: [
            "text": text,
            "userId": userId
        ])
    }

    func deleteComment(commentId: Int) async throws -> DeleteResponse {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        return try await client.delete(APIEndpoint.comment(commentId), parameters: ["userId": userId])
    }
}
