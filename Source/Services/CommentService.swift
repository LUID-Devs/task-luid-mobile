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

    func createComment(taskId: Int, text: String?, imageUrl: String? = nil) async throws -> Comment {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        var params: [String: Any] = [
            "userId": userId
        ]
        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["text"] = text
        }
        if let imageUrl, !imageUrl.isEmpty {
            params["imageUrl"] = imageUrl
        }
        return try await client.post(APIEndpoint.taskComments(taskId), parameters: params)
    }

    func deleteComment(commentId: Int) async throws -> DeleteResponse {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        return try await client.delete(APIEndpoint.comment(commentId), parameters: ["userId": userId])
    }

    func uploadCommentImage(fileURL: URL) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: AppConfig.apiURL(for: APIEndpoint.commentUploadImage))!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpShouldHandleCookies = true

        if let token = keychain.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let idToken = keychain.getIdToken() {
            request.setValue(idToken, forHTTPHeaderField: "X-ID-Token")
        }
        if let activeOrgId = keychain.getActiveOrganizationId(),
           let parsed = Int(activeOrgId),
           parsed > 0 {
            request.setValue(String(parsed), forHTTPHeaderField: "X-Organization-Id")
        }

        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = mimeTypeFor(fileURL: fileURL)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
        }

        let decoded = try JSONDecoder().decode(CommentImageUploadResponse.self, from: data)
        guard let imageUrl = decoded.imageUrl else {
            throw APIError.noData
        }
        return imageUrl
    }

    private func mimeTypeFor(fileURL: URL) -> String {
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }
}

private struct CommentImageUploadResponse: Codable {
    let imageUrl: String?
    let key: String?
}
