//
//  AttachmentService.swift
//  TaskLuid
//

import Foundation

@MainActor
class AttachmentService {
    static let shared = AttachmentService()
    private let client = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    func getTaskAttachments(taskId: Int) async throws -> [Attachment] {
        return try await client.get(APIEndpoint.taskAttachments(taskId))
    }

    func deleteAttachment(attachmentId: Int) async throws -> DeleteResponse {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        return try await client.delete(APIEndpoint.attachment(attachmentId), parameters: ["userId": userId])
    }

    func uploadAttachment(taskId: Int, fileURL: URL) async throws -> Attachment {
        guard let userId = keychain.getUserId(), !userId.isEmpty else {
            throw APIError.serverError("User ID is required.")
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: AppConfig.apiURL(for: APIEndpoint.taskAttachments(taskId)))!)
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
        body.append("Content-Disposition: form-data; name=\"uploadedById\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Attachment.self, from: data)
    }

    private func mimeTypeFor(fileURL: URL) -> String {
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "pdf": return "application/pdf"
        default: return "application/octet-stream"
        }
    }
}
