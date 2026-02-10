//
//  ProjectStatus.swift
//  TaskLuid
//

import Foundation

struct ProjectStatus: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String?
    let order: Int
    let isDefault: Bool
    let projectId: Int
    let createdAt: String
    let updatedAt: String
}
