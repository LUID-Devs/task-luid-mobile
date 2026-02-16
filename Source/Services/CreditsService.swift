//
//  CreditsService.swift
//  TaskLuid
//

import Foundation

@MainActor
class CreditsService {
    static let shared = CreditsService()
    private let client = APIClient.shared

    private init() {}

    func getSubscriptionStatus() async throws -> SubscriptionStatus? {
        let response: SuccessResponse<SubscriptionStatus> = try await client.get(
            APIEndpoint.subscriptionStatus
        )
        return response.data
    }
}
