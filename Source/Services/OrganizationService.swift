//
//  OrganizationService.swift
//  TaskLuid
//

import Foundation

@MainActor
class OrganizationService {
    static let shared = OrganizationService()
    private let client = APIClient.shared

    private init() {}

    private struct InviteResponse: Codable {
        let success: Bool?
        let message: String?
        let invite: OrganizationInvite?
    }

    private struct AcceptInviteResponse: Codable {
        let success: Bool?
        let message: String?
        let data: AcceptInviteData?
    }

    private struct AcceptInviteData: Codable {
        let organization: Organization?
        let member: OrganizationMember?
    }

    func getMembers(organizationId: Int) async throws -> [OrganizationMember] {
        let response: SuccessResponse<[OrganizationMember]> = try await client.get(
            APIEndpoint.organizationMembers(organizationId)
        )
        return response.data ?? []
    }

    func getInvites(organizationId: Int) async throws -> [OrganizationInvite] {
        let response: SuccessResponse<[OrganizationInvite]> = try await client.get(
            APIEndpoint.organizationInvites(organizationId)
        )
        return response.data ?? []
    }

    func resendInvite(organizationId: Int, inviteId: Int) async throws -> OrganizationInvite {
        let response: SuccessResponse<OrganizationInvite> = try await client.post(
            APIEndpoint.organizationInviteResend(organizationId, inviteId: inviteId),
            parameters: [:]
        )
        guard let invite = response.data else {
            throw APIError.noData
        }
        return invite
    }

    func revokeInvite(organizationId: Int, inviteId: Int) async throws -> Bool {
        let response: SuccessResponse<EmptyResponse> = try await client.delete(
            APIEndpoint.organizationInvite(organizationId, inviteId: inviteId),
            parameters: [:]
        )
        return response.success
    }

    func getOrganization(organizationId: Int) async throws -> Organization {
        let response: SuccessResponse<Organization> = try await client.get(
            APIEndpoint.organization(organizationId)
        )
        guard let organization = response.data else {
            throw APIError.noData
        }
        return organization
    }

    func updateOrganization(
        organizationId: Int,
        name: String?,
        description: String?,
        domain: String?
    ) async throws -> Organization {
        var params: [String: Any] = [:]
        if let name {
            params["name"] = name
        }
        if let description {
            params["description"] = description
        }
        if let domain {
            params["domain"] = domain
        }
        let response: SuccessResponse<Organization> = try await client.put(
            APIEndpoint.organization(organizationId),
            parameters: params
        )
        guard let organization = response.data else {
            throw APIError.noData
        }
        return organization
    }

    func leaveOrganization(organizationId: Int) async throws -> Bool {
        let response: SuccessResponse<EmptyResponse> = try await client.post(
            APIEndpoint.organizationLeave(organizationId),
            parameters: [:]
        )
        return response.success
    }

    func updateMemberRole(organizationId: Int, userId: Int, role: String) async throws -> OrganizationMember {
        let params: [String: Any] = ["role": role]
        let response: SuccessResponse<OrganizationMember> = try await client.put(
            APIEndpoint.organizationMember(organizationId, userId: userId),
            parameters: params
        )
        guard let member = response.data else {
            throw APIError.noData
        }
        return member
    }

    func removeMember(organizationId: Int, userId: Int) async throws -> Bool {
        let response: SuccessResponse<EmptyResponse> = try await client.delete(
            APIEndpoint.organizationMember(organizationId, userId: userId),
            parameters: [:]
        )
        return response.success
    }

    func createInvite(organizationId: Int, email: String, role: String, message: String?) async throws -> OrganizationInvite {
        var params: [String: Any] = ["email": email, "role": role]
        if let message, !message.isEmpty {
            params["message"] = message
        }
        let response: InviteResponse = try await client.post(
            APIEndpoint.organizationInvites(organizationId),
            parameters: params
        )
        guard let invite = response.invite else {
            throw APIError.noData
        }
        return invite
    }

    func getMyInvites() async throws -> [OrganizationInvite] {
        let response: SuccessResponse<[OrganizationInvite]> = try await client.get(
            APIEndpoint.organizationMyInvites
        )
        return response.data ?? []
    }

    func acceptInvite(token: String) async throws -> (organization: Organization?, member: OrganizationMember?) {
        let response: AcceptInviteResponse = try await client.post(
            APIEndpoint.organizationAcceptInvite(token),
            parameters: [:]
        )
        return (response.data?.organization, response.data?.member)
    }

    func getAuditLogs(organizationId: Int, limit: Int = 20) async throws -> [OrganizationAuditLog] {
        let response: AuditLogResponse = try await client.get(
            APIEndpoint.organizationAuditLogs(organizationId),
            parameters: ["limit": limit]
        )
        return response.data ?? []
    }
}

private struct EmptyResponse: Codable {}

private struct AuditLogResponse: Codable {
    let success: Bool?
    let data: [OrganizationAuditLog]?
}
