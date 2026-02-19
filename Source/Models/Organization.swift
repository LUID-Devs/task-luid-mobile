//
//  Organization.swift
//  TaskLuid
//

import Foundation

struct OrganizationSettings: Codable {
    let isPersonal: Bool?
}

struct Organization: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String?
    let description: String?
    let logoUrl: String?
    let domain: String?
    let settings: OrganizationSettings?
    let role: String?
    let joinedAt: String?
}
