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
    let settings: OrganizationSettings?
}
