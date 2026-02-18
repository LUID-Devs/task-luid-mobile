//
//  AIParsedTask.swift
//  TaskLuid
//

import Foundation

struct AIParseTaskResponse: Codable {
    let success: Bool?
    let data: AIParsedTask?
    let creditsUsed: Int?
    let remainingCredits: Int?
    let error: AIServiceError?
}

struct AIParsedTask: Codable {
    let title: String?
    let description: String?
    let priority: String?
    let dueDate: String?
    let assignee: String?
    let tags: String?
}

struct AIServiceError: Codable {
    let message: String?
    let code: String?
    let required: Int?
    let available: Int?
}
