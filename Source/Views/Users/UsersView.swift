//
//  UsersView.swift
//  TaskLuid
//

import SwiftUI

struct UsersView: View {
    @StateObject private var viewModel = OrganizationMembersViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var viewMode = "Cards"
    @State private var searchText = ""
    @State private var roleFilter: String? = nil
    @State private var showInviteSheet = false
    @State private var selectedMember: OrganizationMember? = nil
    @State private var showRoleDialog = false
    @State private var inviteEmail = ""
    @State private var inviteRole = "member"
    @State private var inviteMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                headerRow

                if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                }
                if let inviteError = viewModel.inviteErrorMessage {
                    InlineErrorView(message: inviteError)
                }

                if !viewModel.invites.isEmpty {
                    invitesSection
                }

                if viewModel.isLoading || viewModel.isInvitesLoading {
                    LLLoadingView("Loading users...")
                } else if filteredMembers.isEmpty && viewModel.invites.isEmpty {
                    LLEmptyState(
                        icon: "person.2",
                        title: "No users",
                        message: "Invite teammates to see them here."
                    )
                } else {
                    filterBar
                    viewToggleRow

                    if viewMode == "Table" {
                        tableView
                    } else {
                        ForEach(filteredMembers) { member in
                            memberCard(member)
                        }
                    }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
        .task(id: organizationId) {
            guard let organizationId else { return }
            await viewModel.loadMembers(organizationId: organizationId)
        }
        .task {
            await viewModel.loadMyInvites()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
        }
        .confirmationDialog("Set role", isPresented: $showRoleDialog) {
            ForEach(roleOptions, id: \.self) { role in
                Button(role.capitalized) {
                    Task {
                        await updateRole(role)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var organizationId: Int? {
        if let stored = KeychainManager.shared.getActiveOrganizationId(),
           let parsed = Int(stored) {
            return parsed
        }
        return nil
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView("Users", subtitle: "Manage people in your workspace.")
            Spacer()
            Button {
                showInviteSheet = true
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }
        }
    }

    private var filterBar: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Search & Filter")
                    .h4()
                SearchBarView(placeholder: "Search members", text: $searchText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        Menu {
                            Button("All roles") { roleFilter = nil }
                            ForEach(roleOptions, id: \.self) { role in
                                Button(role.capitalized) { roleFilter = role }
                            }
                        } label: {
                            filterChipLabel("Role", value: roleFilter?.capitalized)
                        }

                        if hasActiveFilters {
                            LLButton("Clear", style: .ghost, size: .sm) {
                                searchText = ""
                                roleFilter = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private var invitesSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Invitations")
                    .h4()
                ForEach(viewModel.invites) { invite in
                    HStack(alignment: .top, spacing: LLSpacing.sm) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(invite.organization?.name ?? "Workspace")
                                .bodyText()
                            Text(invite.email)
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            HStack(spacing: LLSpacing.xs) {
                                Text("Role")
                                    .captionText()
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                LLBadge(invite.role.capitalized, variant: .outline, size: .sm)
                            }
                        }
                        Spacer()
                        LLButton("Accept", style: .primary, size: .sm, isLoading: viewModel.isInvitesLoading) {
                            Task {
                                await acceptInvite(invite)
                            }
                        }
                    }
                    if invite.id != viewModel.invites.last?.id {
                        Divider()
                            .background(LLColors.muted.color(for: colorScheme))
                    }
                }
            }
        }
    }

    private var viewToggleRow: some View {
        HStack(spacing: LLSpacing.sm) {
            Text("View")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Button {
                viewMode = "Cards"
            } label: {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(viewMode == "Cards" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "Cards" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Button {
                viewMode = "Table"
            } label: {
                Image(systemName: "tablecells")
                    .foregroundColor(viewMode == "Table" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "Table" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }

    private func memberCard(_ member: OrganizationMember) -> some View {
        LLCard(style: .standard) {
            HStack(spacing: LLSpacing.sm) {
                let isOwner = member.role.lowercased() == "owner"
                Circle()
                    .fill(LLColors.muted.color(for: colorScheme))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(member.user?.username.prefix(1) ?? "?").uppercased())
                            .bodyText()
                    )

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text(member.user?.username ?? "User")
                        .h4()
                    Text(member.user?.email ?? "No email")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()

                LLBadge(member.role.capitalized, variant: .outline, size: .sm)
                if isOwner {
                    LLButton("Owner", style: .ghost, size: .sm) {}
                        .disabled(true)
                } else {
                    LLButton("Manage", style: .outline, size: .sm) {
                        selectedMember = member
                        showRoleDialog = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tableView: some View {
        let roleWidth: CGFloat = 90
        LLCard(style: .standard) {
            VStack(spacing: LLSpacing.sm) {
                HStack {
                    Text("User")
                        .captionText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                    Text("Role")
                        .captionText()
                        .frame(width: roleWidth, alignment: .leading)
                    Text("Actions")
                        .captionText()
                        .frame(width: 80, alignment: .leading)
                }
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Divider()
                    .background(LLColors.muted.color(for: colorScheme))

                ForEach(filteredMembers) { member in
                    HStack {
                        let isOwner = member.role.lowercased() == "owner"
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(member.user?.username ?? "User")
                                .bodyText()
                            Text(member.user?.email ?? "No email")
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                        Text(member.role.capitalized)
                            .bodySmall()
                            .frame(width: roleWidth, alignment: .leading)
                        Group {
                            if isOwner {
                                Text("Owner")
                                    .bodySmall()
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            } else {
                                Button("Manage") {
                                    selectedMember = member
                                    showRoleDialog = true
                                }
                            }
                        }
                        .frame(width: 80, alignment: .leading)
                    }
                    Divider()
                        .background(LLColors.muted.color(for: colorScheme))
                }
            }
        }
    }

    private var inviteSheet: some View {
        VStack(spacing: LLSpacing.lg) {
            Text("Invite user")
                .h3()
            LLTextField(title: "Email", placeholder: "name@company.com", text: $inviteEmail)
            LLTextField(title: "Message (optional)", placeholder: "Add a message", text: $inviteMessage)
            Menu {
                ForEach(roleOptions, id: \.self) { role in
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

            if let message = viewModel.inviteMessage {
                InlineErrorView(message: message)
            }

            HStack(spacing: LLSpacing.sm) {
                LLButton("Cancel", style: .outline, size: .sm, fullWidth: true) {
                    showInviteSheet = false
                }
                LLButton("Send invite", style: .primary, size: .sm, isLoading: viewModel.isLoading, fullWidth: true) {
                    Task { await sendInvite() }
                }
            }
        }
        .screenPadding()
    }

    private func sendInvite() async {
        guard let organizationId else {
            viewModel.errorMessage = "Organization not available."
            return
        }
        let email = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            viewModel.errorMessage = "Email is required."
            return
        }
        let success = await viewModel.inviteMember(
            organizationId: organizationId,
            email: email,
            role: inviteRole,
            message: inviteMessage
        )
        if success {
            inviteEmail = ""
            inviteMessage = ""
            showInviteSheet = false
        }
    }

    private func updateRole(_ role: String) async {
        guard let organizationId,
              let member = selectedMember else { return }
        let _ = await viewModel.updateRole(
            organizationId: organizationId,
            userId: member.userId,
            role: role
        )
    }

    private func acceptInvite(_ invite: OrganizationInvite) async {
        guard let token = invite.token else {
            viewModel.inviteErrorMessage = "Invite token missing."
            return
        }
        let success = await viewModel.acceptInvite(token: token)
        if success, let organizationId {
            await viewModel.loadMembers(organizationId: organizationId)
        }
    }

    private func filterChipLabel(_ title: String, value: String?) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Text(title)
                .bodySmall()
            if let value, !value.isEmpty {
                LLBadge(value, variant: .outline, size: .sm)
            } else {
                Text("All")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding(.horizontal, LLSpacing.sm)
        .padding(.vertical, LLSpacing.xs)
        .background(LLColors.muted.color(for: colorScheme))
        .cornerRadius(12)
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || roleFilter != nil
    }

    private var roleOptions: [String] {
        ["admin", "member", "viewer"]
    }

    private var filteredMembers: [OrganizationMember] {
        let searched = viewModel.members.filter { member in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let username = member.user?.username.lowercased() ?? ""
            let email = member.user?.email?.lowercased() ?? ""
            return username.contains(query) || email.contains(query)
        }

        return searched.filter { member in
            guard let roleFilter else { return true }
            return member.role.lowercased() == roleFilter.lowercased()
        }
    }
}
