//
//  Team.swift
//  TaskLuid
//

import Foundation

struct Team: Codable, Identifiable {
    let teamId: Int
    let teamName: String
    let productOwnerUserId: Int?
    let projectManagerUserId: Int?
    let productOwnerUsername: String?
    let projectManagerUsername: String?

    var id: Int { teamId }

    enum CodingKeys: String, CodingKey {
        case teamId = "id"
        case teamName
        case productOwnerUserId
        case projectManagerUserId
        case productOwnerUsername
        case projectManagerUsername
    }
}
