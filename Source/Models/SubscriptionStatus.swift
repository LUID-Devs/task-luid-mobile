//
//  SubscriptionStatus.swift
//  TaskLuid
//

import Foundation

struct SubscriptionStatus: Codable {
    let status: String?
    let planType: String?
    let currentPeriodEnd: String?
    let cancelAtPeriodEnd: Bool?
    let features: [String: Bool]?

    enum CodingKeys: String, CodingKey {
        case status
        case planType
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case features
    }
}
