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

    var id: Int { teamId }
}
