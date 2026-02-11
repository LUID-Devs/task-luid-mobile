//
//  TeamsView.swift
//  TaskLuid
//

import SwiftUI

struct TeamsView: View {
    @StateObject private var viewModel = TeamsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Teams"

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
                    UsersListView()
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
    }
}
