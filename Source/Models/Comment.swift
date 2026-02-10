//
//  Comment.swift
//  TaskLuid
//

import Foundation

struct CommentUser: Codable {
    let userId: Int
    let username: String
    let email: String?
    let profilePictureUrl: String?
}

struct Comment: Codable, Identifiable {
    let id: Int
    let text: String
    let imageUrl: String?
    let taskId: Int
    let userId: Int
    let createdAt: String
    let updatedAt: String
    let user: CommentUser
}
