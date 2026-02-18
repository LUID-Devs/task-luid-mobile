//
//  OrganizationAuditLog.swift
//  TaskLuid
//

import Foundation

struct OrganizationAuditLog: Codable, Identifiable {
    let id: Int
    let organizationId: Int
    let userId: Int
    let action: String
    let resourceType: String
    let resourceId: Int?
    let resourceName: String?
    let details: JSONValue?
    let createdAt: String
    let user: OrganizationAuditUser?
}

struct OrganizationAuditUser: Codable, Identifiable {
    let userId: Int
    let username: String
    let profilePictureUrl: String?

    var id: Int { userId }
}
