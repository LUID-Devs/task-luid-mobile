//
//  OrganizationInvite.swift
//  TaskLuid
//

import Foundation

struct OrganizationInvite: Codable, Identifiable {
    let id: Int
    let email: String
    let role: String
    let inviteUrl: String?
    let expiresAt: String?
    let token: String?
    let status: String?
    let message: String?
    let organization: Organization?
    let inviter: User?
}
