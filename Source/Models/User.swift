//
//  User.swift
//  TaskLuid
//

import Foundation

struct User: Codable, Identifiable {
    let userId: Int
    let username: String
    let email: String?
    let profilePictureUrl: String?
    let cognitoId: String?
    let teamId: Int?
    let role: String?

    var id: Int { userId }
}
