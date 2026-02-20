//
//  TeamsView.swift
//  TaskLuid
//

import SwiftUI
import UIKit

struct TeamsView: View {
    @StateObject private var viewModel = TeamsViewModel()
    @StateObject private var membersViewModel = OrganizationMembersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Teams"
    @State private var peopleViewMode = "Cards"
    @State private var peopleSearchText = ""
    @State private var roleFilter: String? = nil
    @State private var exportNotice: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Teams", subtitle: "Manage people and roles.")

                Picker("View", selection: $selectedTab) {
                    Text("Teams").tag("Teams")
                    Text("People").tag("People")
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedTab == "Teams" {
                    Group {
                        if viewModel.isLoading {
                            LLLoadingView("Loading teams...")
                        } else if viewModel.teams.isEmpty {
                            LLEmptyState(
                                icon: "person.3",
                                title: "No teams",
                                message: "Teams will appear here once created."
                            )
                        } else {
                            VStack(spacing: LLSpacing.md) {
                                ForEach(viewModel.teams) { team in
                                    LLCard(style: .standard) {
                                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                            Text(team.teamName)
                                                .h4()
                                            Text("Team ID: \(team.teamId)")
                                                .bodySmall()
                                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .task {
                        await viewModel.loadTeams()
                    }
                } else {
                    peopleView
                }
            }
            .screenPadding()
        }
        .appBackground()
    }

    private var peopleView: some View {
        VStack(spacing: LLSpacing.md) {
            if let exportNotice {
                LLCard(style: .standard) {
                    Text(exportNotice)
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }

            if membersViewModel.isLoading || membersViewModel.isInvitesLoading {
                LLLoadingView("Loading people...")
            } else if let errorMessage = membersViewModel.errorMessage ?? membersViewModel.inviteErrorMessage {
                InlineErrorView(message: errorMessage)
            } else if filteredMembers.isEmpty {
                LLEmptyState(
                    icon: "person.3",
                    title: "No members",
                    message: "Members will appear here once added."
                )
            } else {
                statsCard
                peopleFilterBar
                peopleViewToggle

                if peopleViewMode == "Table" {
                    membersTable
                } else {
                    ForEach(filteredMembers) { member in
                        memberCard(member)
                    }
                }
            }
        }
        .task(id: organizationId) {
            guard let organizationId else { return }
            await membersViewModel.loadMembers(organizationId: organizationId)
        }
    }

    private var statsCard: some View {
        let total = membersViewModel.members.count
        let owners = membersViewModel.members.filter { $0.role.lowercased() == "owner" }.count
        let admins = membersViewModel.members.filter { $0.role.lowercased() == "admin" }.count
        let members = membersViewModel.members.filter { $0.role.lowercased() == "member" }.count
        let viewers = membersViewModel.members.filter { $0.role.lowercased() == "viewer" }.count

        let stats: [(String, Int)] = {
            var base = [("Total Members", total), ("Owners", owners), ("Admins", admins), ("Members", members)]
            if viewers > 0 {
                base.append(("Viewers", viewers))
            }
            return base
        }()

        return LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Team Overview")
                    .h4()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.sm) {
                    ForEach(stats, id: \.0) { label, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(label)
                                .captionText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            Text("\(value)")
                                .h4()
                        }
                        .padding(LLSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LLColors.muted.color(for: colorScheme))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var peopleFilterBar: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Search & Filter")
                    .h4()
                SearchBarView(placeholder: "Search members", text: $peopleSearchText)

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

                        LLButton("Export", style: .outline, size: .sm) {
                            exportMembers()
                        }

                        if hasActiveFilters {
                            LLButton("Clear", style: .ghost, size: .sm) {
                                peopleSearchText = ""
                                roleFilter = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private var peopleViewToggle: some View {
        HStack(spacing: LLSpacing.sm) {
            Text("View")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Button {
                peopleViewMode = "Cards"
            } label: {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(peopleViewMode == "Cards" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(peopleViewMode == "Cards" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Button {
                peopleViewMode = "Table"
            } label: {
                Image(systemName: "tablecells")
                    .foregroundColor(peopleViewMode == "Table" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(peopleViewMode == "Table" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }

    private func memberCard(_ member: OrganizationMember) -> some View {
        LLCard(style: .standard) {
            HStack(spacing: LLSpacing.md) {
                Circle()
                    .fill(LLColors.muted.color(for: colorScheme))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(member.user?.username.prefix(1) ?? "?").uppercased())
                            .font(LLTypography.h4())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
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
            }
        }
    }

    @ViewBuilder
    private var membersTable: some View {
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
                }
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Divider()
                    .background(LLColors.muted.color(for: colorScheme))

                ForEach(filteredMembers) { member in
                    HStack {
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
                    }
                    Divider()
                        .background(LLColors.muted.color(for: colorScheme))
                }
            }
        }
    }

    private func exportMembers() {
        let csv = membersCSV(from: filteredMembers)
        UIPasteboard.general.string = csv
        exportNotice = "Exported \(filteredMembers.count) members to clipboard."
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            exportNotice = nil
        }
    }

    private func membersCSV(from members: [OrganizationMember]) -> String {
        var rows = ["name,email,role"]
        for member in members {
            let name = member.user?.username ?? ""
            let email = member.user?.email ?? ""
            let role = member.role
            rows.append("\(sanitizeCSV(name)),\(sanitizeCSV(email)),\(sanitizeCSV(role))")
        }
        return rows.joined(separator: "\n")
    }

    private func sanitizeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
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
        !peopleSearchText.isEmpty || roleFilter != nil
    }

    private var roleOptions: [String] {
        ["owner", "admin", "member", "viewer"]
    }

    private var filteredMembers: [OrganizationMember] {
        let searched = membersViewModel.members.filter { member in
            guard !peopleSearchText.isEmpty else { return true }
            let query = peopleSearchText.lowercased()
            let username = member.user?.username.lowercased() ?? ""
            let email = member.user?.email?.lowercased() ?? ""
            return username.contains(query) || email.contains(query)
        }

        return searched.filter { member in
            guard let roleFilter else { return true }
            return member.role.lowercased() == roleFilter.lowercased()
        }
    }

    private var organizationId: Int? {
        if let stored = KeychainManager.shared.getActiveOrganizationId(),
           let parsed = Int(stored) {
            return parsed
        }
        return nil
    }
}
