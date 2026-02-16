//
//  OrganizationMember.swift
//  TaskLuid
//

import Foundation

struct OrganizationMember: Codable, Identifiable {
    let id: Int
    let userId: Int
    let organizationId: Int
    let role: String
    let status: String?
    let permissions: JSONValue?
    let invitedBy: Int?
    let joinedAt: String?
    let lastActiveAt: String?
    let user: User?
    let inviter: OrganizationMemberUser?
}

struct OrganizationMemberUser: Codable, Identifiable {
    let userId: Int
    let username: String
    let email: String?

    var id: Int { userId }
}
