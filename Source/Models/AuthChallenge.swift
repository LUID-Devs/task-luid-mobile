//
//  AuthChallenge.swift
//  TaskLuid
//

import Foundation

struct AuthChallenge: Codable, Identifiable {
    let challenge: String
    let session: String
    let challengeParameters: [String: String]?

    var id: String { "\(challenge)-\(session)" }
}
