//
//  UsersView.swift
//  TaskLuid
//

import SwiftUI

struct UsersView: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Users", subtitle: "Manage people in your workspace.")

                if viewModel.isLoading {
                    LLLoadingView("Loading users...")
                } else if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                } else if viewModel.users.isEmpty {
                    LLEmptyState(
                        icon: "person.2",
                        title: "No users",
                        message: "Invite teammates to see them here."
                    )
                } else {
                    ForEach(viewModel.users) { user in
                        LLCard(style: .standard) {
                            HStack(spacing: LLSpacing.sm) {
                                Circle()
                                    .fill(LLColors.muted.color(for: colorScheme))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(user.username.prefix(1)).uppercased())
                                            .bodyText()
                                    )

                                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                    Text(user.username)
                                        .h4()
                                    Text(user.email ?? "No email")
                                        .bodySmall()
                                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                }

                                Spacer()

                                if let role = user.role {
                                    LLBadge(role.capitalized, variant: .outline, size: .sm)
                                }
                            }
                        }
                    }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
        .task {
            await viewModel.loadUsers()
        }
    }
}
