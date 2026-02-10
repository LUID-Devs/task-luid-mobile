//
//  UsersListView.swift
//  TaskLuid
//

import SwiftUI

struct UsersListView: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if viewModel.isLoading {
                LLLoadingView("Loading people...")
            } else if viewModel.users.isEmpty {
                LLEmptyState(
                    icon: "person",
                    title: "No users",
                    message: "Users will appear here once added."
                )
            } else {
                VStack(spacing: LLSpacing.md) {
                    ForEach(viewModel.users) { user in
                        LLCard(style: .standard) {
                            HStack(spacing: LLSpacing.md) {
                                Circle()
                                    .fill(LLColors.muted.color(for: colorScheme))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(String(user.username.prefix(1)).uppercased())
                                            .font(LLTypography.h4())
                                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
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
                                    LLBadge(role.replacingOccurrences(of: "_", with: " ").capitalized, variant: .outline, size: .sm)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }
}
