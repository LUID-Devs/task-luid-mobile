//
//  SettingsView.swift
//  TaskLuid
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var profileUsername = ""
    @State private var profileEmail = ""
    @State private var profileMessage: String? = nil
    @State private var profileError: String? = nil

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordMessage: String? = nil
    @State private var passwordError: String? = nil

    @State private var orgName = ""
    @State private var orgDescription = ""
    @State private var orgDomain = ""
    @State private var orgMessage: String? = nil
    @State private var orgError: String? = nil
    @State private var showLeaveDialog = false

    @State private var inviteEmail = ""
    @State private var inviteRole = "member"
    @State private var inviteMessage = ""
    @State private var inviteNotice: String? = nil
    @State private var inviteError: String? = nil

    @State private var subscriptionStatus: SubscriptionStatus? = nil
    @State private var isLoading = false
    @State private var isOrgLoading = false
    @State private var isInviteLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Settings", subtitle: "Manage your account.")

                profileSection
                passwordSection
                workspaceSection
                inviteSection
                subscriptionSection

                LLButton("Logout", style: .destructive, fullWidth: true) {
                    Task { await authViewModel.logout() }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
        .task {
            await loadInitialData()
        }
        .confirmationDialog("Leave workspace?", isPresented: $showLeaveDialog) {
            Button("Leave", role: .destructive) {
                Task { await leaveWorkspace() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will lose access to this workspace.")
        }
    }

    private var profileSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Profile")
                    .h4()
                if let profileMessage {
                    noticeView(message: profileMessage)
                }
                if let profileError {
                    InlineErrorView(message: profileError)
                }
                LLTextField(title: "Username", placeholder: "Your name", text: $profileUsername)
                LLTextField(title: "Email", placeholder: "you@email.com", text: $profileEmail)
                LLButton("Save Profile", style: .primary, size: .sm, isLoading: isLoading, fullWidth: true) {
                    Task { await saveProfile() }
                }
            }
        }
    }

    private var passwordSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Security")
                    .h4()
                if let passwordMessage {
                    noticeView(message: passwordMessage)
                }
                if let passwordError {
                    InlineErrorView(message: passwordError)
                }
                LLTextField(title: "Current password", placeholder: "••••••••", text: $currentPassword, isSecure: true)
                LLTextField(title: "New password", placeholder: "••••••••", text: $newPassword, isSecure: true)
                LLTextField(title: "Confirm password", placeholder: "••••••••", text: $confirmPassword, isSecure: true)
                LLButton("Change Password", style: .outline, size: .sm, isLoading: isLoading, fullWidth: true) {
                    Task { await changePassword() }
                }
            }
        }
    }

    private var workspaceSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Workspace")
                    .h4()
                if let orgMessage {
                    noticeView(message: orgMessage)
                }
                if let orgError {
                    InlineErrorView(message: orgError)
                }
                LLTextField(title: "Name", placeholder: "Workspace name", text: $orgName)
                LLTextField(title: "Description", placeholder: "Optional description", text: $orgDescription)
                LLTextField(title: "Domain", placeholder: "Optional domain", text: $orgDomain)
                LLButton("Save Workspace", style: .primary, size: .sm, isLoading: isOrgLoading, fullWidth: true) {
                    Task { await saveWorkspace() }
                }
                LLButton("Leave Workspace", style: .destructive, size: .sm, fullWidth: true) {
                    showLeaveDialog = true
                }
            }
        }
    }

    private var inviteSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Invite to Workspace")
                    .h4()
                if let inviteNotice {
                    noticeView(message: inviteNotice)
                }
                if let inviteError {
                    InlineErrorView(message: inviteError)
                }
                LLTextField(title: "Email", placeholder: "name@company.com", text: $inviteEmail)
                LLTextField(title: "Message (optional)", placeholder: "Add a message", text: $inviteMessage)
                Menu {
                    ForEach(["admin", "member", "viewer"], id: \.self) { role in
                        Button(role.capitalized) {
                            inviteRole = role
                        }
                    }
                } label: {
                    HStack(spacing: LLSpacing.xs) {
                        Text("Role")
                            .bodySmall()
                        LLBadge(inviteRole.capitalized, variant: .outline, size: .sm)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                    .padding(.horizontal, LLSpacing.sm)
                    .padding(.vertical, LLSpacing.xs)
                    .background(LLColors.muted.color(for: colorScheme))
                    .cornerRadius(12)
                }
                LLButton("Send Invite", style: .outline, size: .sm, isLoading: isInviteLoading, fullWidth: true) {
                    Task { await sendInvite() }
                }
            }
        }
    }

    private var subscriptionSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Subscription")
                    .h4()
                if let status = subscriptionStatus {
                    HStack {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(status.planType?.capitalized ?? "Free")
                                .h4()
                            Text(status.status?.capitalized ?? "Unknown")
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        Spacer()
                        if status.cancelAtPeriodEnd == true {
                            LLBadge("Cancels soon", variant: .outline, size: .sm)
                        }
                    }
                    if let end = status.currentPeriodEnd {
                        Text("Renews: \(end)")
                            .bodySmall()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                } else {
                    Text("Subscription details unavailable.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }

    private func loadInitialData() async {
        if let user = authViewModel.user {
            profileUsername = user.username
            profileEmail = user.email ?? ""
        }

        if let organizationId {
            isOrgLoading = true
            defer { isOrgLoading = false }

            do {
                let organization = try await OrganizationService.shared.getOrganization(organizationId: organizationId)
                orgName = organization.name
                orgDescription = organization.description ?? ""
                orgDomain = organization.domain ?? ""
            } catch {
                orgError = error.localizedDescription
            }
        }

        do {
            subscriptionStatus = try await CreditsService.shared.getSubscriptionStatus()
        } catch {
            // Ignore subscription errors for now
        }
    }

    private func saveProfile() async {
        guard let userId = authViewModel.user?.userId else { return }
        profileMessage = nil
        profileError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let updated = try await UserService.shared.updateProfile(
                userId: userId,
                username: profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileUsername,
                email: profileEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileEmail
            )
            authViewModel.user = updated
            profileMessage = "Profile updated."
        } catch {
            profileError = error.localizedDescription
        }
    }

    private func changePassword() async {
        passwordMessage = nil
        passwordError = nil

        guard !currentPassword.isEmpty, !newPassword.isEmpty else {
            passwordError = "Current and new password are required."
            return
        }

        guard newPassword == confirmPassword else {
            passwordError = "Passwords do not match."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await AuthService.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            passwordMessage = "Password updated."
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            passwordError = error.localizedDescription
        }
    }

    private func saveWorkspace() async {
        guard let organizationId else { return }
        orgMessage = nil
        orgError = nil
        isOrgLoading = true
        defer { isOrgLoading = false }

        do {
            let organization = try await OrganizationService.shared.updateOrganization(
                organizationId: organizationId,
                name: orgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : orgName,
                description: orgDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : orgDescription,
                domain: orgDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : orgDomain
            )
            orgName = organization.name
            orgDescription = organization.description ?? ""
            orgDomain = organization.domain ?? ""
            orgMessage = "Workspace updated."
        } catch {
            orgError = error.localizedDescription
        }
    }

    private func leaveWorkspace() async {
        guard let organizationId else { return }
        orgMessage = nil
        orgError = nil
        isOrgLoading = true
        defer { isOrgLoading = false }

        do {
            _ = try await OrganizationService.shared.leaveOrganization(organizationId: organizationId)
            _ = KeychainManager.shared.saveActiveOrganizationId("")
            orgMessage = "You left the workspace."
        } catch {
            orgError = error.localizedDescription
        }
    }

    private func sendInvite() async {
        guard let organizationId else {
            inviteError = "Workspace not available."
            return
        }
        inviteNotice = nil
        inviteError = nil
        let email = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            inviteError = "Email is required."
            return
        }

        isInviteLoading = true
        defer { isInviteLoading = false }

        do {
            let invite = try await OrganizationService.shared.createInvite(
                organizationId: organizationId,
                email: email,
                role: inviteRole,
                message: inviteMessage
            )
            inviteNotice = "Invite sent to \(invite.email)."
            inviteEmail = ""
            inviteMessage = ""
        } catch {
            inviteError = error.localizedDescription
        }
    }

    private func noticeView(message: String) -> some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(LLColors.primary.color(for: colorScheme))
            Text(message)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
        .padding(LLSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LLColors.card.color(for: colorScheme))
        .cornerRadius(LLSpacing.radiusMD)
    }

    private var organizationId: Int? {
        if let stored = KeychainManager.shared.getActiveOrganizationId(),
           let parsed = Int(stored) {
            return parsed
        }
        return nil
    }
}
