//
//  DashboardView.swift
//  TaskLuid
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LLLoadingView("Loading dashboard...")
                } else {
                    ScrollView {
                        VStack(spacing: LLSpacing.lg) {
                            headerSection
                            summarySection
                            quickActionsSection
                            recentProjectsSection
                        }
                        .screenPadding()
                    }
                    .background(LLColors.background.color(for: colorScheme))
                }
            }
            .navigationTitle("Dashboard")
            .task {
                if let userId = authViewModel.user?.userId {
                    await viewModel.loadDashboard(userId: userId)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            SectionHeaderView("Welcome back", subtitle: "Here is your project pulse today.")
            HStack(spacing: LLSpacing.sm) {
                StatPillView(title: "Active projects", value: "\(viewModel.summary?.projectCount ?? 0)")
                StatPillView(title: "Tasks", value: "\(viewModel.summary?.taskCount ?? 0)")
            }
        }
    }

    private var summarySection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Overview")
                    .h4()

                if let summary = viewModel.summary {
                    HStack(spacing: LLSpacing.md) {
                        summaryItem(title: "Projects", value: "\(summary.projectCount)")
                        summaryItem(title: "Tasks", value: "\(summary.taskCount)")
                        summaryItem(title: "Done", value: "\(summary.completedCount)")
                    }

                    HStack(spacing: LLSpacing.md) {
                        summaryItem(title: "In Progress", value: "\(summary.inProgressCount)")
                    }
                } else {
                    Text("No data yet.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Recent projects")
                .h4()

            if viewModel.recentProjects.isEmpty {
                Text("Create a project to get started.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            } else {
                ForEach(viewModel.recentProjects) { project in
                    ProjectRowView(project: project)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Quick actions")
                .h4()
            HStack(spacing: LLSpacing.sm) {
                LLButton("New project", style: .primary, size: .sm, fullWidth: true) {}
                LLButton("New task", style: .outline, size: .sm, fullWidth: true) {}
            }
        }
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(title)
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Text(value)
                .h4()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
