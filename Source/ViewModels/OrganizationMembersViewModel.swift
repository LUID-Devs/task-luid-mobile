//
//  OrganizationMembersViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class OrganizationMembersViewModel: ObservableObject {
    @Published var members: [OrganizationMember] = []
    @Published var invites: [OrganizationInvite] = []
    @Published var pendingInvites: [OrganizationInvite] = []
    @Published var auditLogs: [OrganizationAuditLog] = []
    @Published var isLoading = false
    @Published var isInvitesLoading = false
    @Published var isAuditLoading = false
    @Published var errorMessage: String? = nil
    @Published var inviteErrorMessage: String? = nil
    @Published var auditErrorMessage: String? = nil
    @Published var inviteMessage: String? = nil

    private let organizationService = OrganizationService.shared

    func loadMembers(organizationId: Int) async {
        if isLoading {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            members = try await organizationService.getMembers(organizationId: organizationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateRole(organizationId: Int, userId: Int, role: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let member = try await organizationService.updateMemberRole(
                organizationId: organizationId,
                userId: userId,
                role: role
            )
            if let index = members.firstIndex(where: { $0.userId == userId }) {
                members[index] = member
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func inviteMember(organizationId: Int, email: String, role: String, message: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        inviteMessage = nil
        defer { isLoading = false }

        do {
            let invite = try await organizationService.createInvite(
                organizationId: organizationId,
                email: email,
                role: role,
                message: message
            )
            inviteMessage = "Invitation sent to \(invite.email)"
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadInvites(organizationId: Int) async {
        if isInvitesLoading {
            return
        }
        isInvitesLoading = true
        inviteErrorMessage = nil
        defer { isInvitesLoading = false }

        do {
            pendingInvites = try await organizationService.getInvites(organizationId: organizationId)
        } catch {
            inviteErrorMessage = error.localizedDescription
        }
    }

    func resendInvite(organizationId: Int, inviteId: Int) async -> Bool {
        isInvitesLoading = true
        inviteErrorMessage = nil
        defer { isInvitesLoading = false }

        do {
            let updated = try await organizationService.resendInvite(organizationId: organizationId, inviteId: inviteId)
            if let index = pendingInvites.firstIndex(where: { $0.id == updated.id }) {
                pendingInvites[index] = updated
            }
            return true
        } catch {
            inviteErrorMessage = error.localizedDescription
            return false
        }
    }

    func revokeInvite(organizationId: Int, inviteId: Int) async -> Bool {
        isInvitesLoading = true
        inviteErrorMessage = nil
        defer { isInvitesLoading = false }

        do {
            _ = try await organizationService.revokeInvite(organizationId: organizationId, inviteId: inviteId)
            pendingInvites.removeAll { $0.id == inviteId }
            return true
        } catch {
            inviteErrorMessage = error.localizedDescription
            return false
        }
    }

    func removeMember(organizationId: Int, userId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await organizationService.removeMember(organizationId: organizationId, userId: userId)
            members.removeAll { $0.userId == userId }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadMyInvites() async {
        if isInvitesLoading {
            return
        }
        isInvitesLoading = true
        inviteErrorMessage = nil
        defer { isInvitesLoading = false }

        do {
            invites = try await organizationService.getMyInvites()
        } catch {
            inviteErrorMessage = error.localizedDescription
        }
    }

    func acceptInvite(token: String) async -> Bool {
        isInvitesLoading = true
        inviteErrorMessage = nil
        defer { isInvitesLoading = false }

        do {
            let result = try await organizationService.acceptInvite(token: token)
            if let organizationId = result.organization?.id {
                _ = KeychainManager.shared.saveActiveOrganizationId(String(organizationId))
            }
            invites.removeAll { $0.token == token }
            return true
        } catch {
            inviteErrorMessage = error.localizedDescription
            return false
        }
    }

    func loadAuditLogs(organizationId: Int) async {
        if isAuditLoading {
            return
        }
        isAuditLoading = true
        auditErrorMessage = nil
        defer { isAuditLoading = false }

        do {
            auditLogs = try await organizationService.getAuditLogs(organizationId: organizationId)
        } catch {
            auditErrorMessage = error.localizedDescription
        }
    }
}
