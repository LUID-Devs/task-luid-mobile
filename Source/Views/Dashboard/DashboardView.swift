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
        Group {
            if viewModel.isLoading {
                LLLoadingView("Loading dashboard...")
            } else {
                ScrollView {
                    VStack(spacing: LLSpacing.lg) {
                        headerSection
                        welcomeCard
                        planCard
                        statGrid
                        recentTasksSection
                    }
                    .screenPadding()
                }
                .background(LLColors.background.color(for: colorScheme))
            }
        }
        .task(id: authViewModel.user?.userId) {
            if let userId = authViewModel.user?.userId {
                await viewModel.loadDashboard(userId: userId)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text("Project Management Dashboard")
                .h3()
            Text("Overview of your work and recent activity.")
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    private var welcomeCard: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Welcome back, \(authViewModel.user?.username ?? "User")!")
                    .h4()
                Text("Here’s your project overview and recent activity.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private var planCard: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack {
                    Text("Current Plan: Free")
                        .h4()
                    Spacer()
                    LLBadge("Free", variant: .outline, size: .sm)
                }
                Text("Limited access — upgrade for more.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                HStack(spacing: LLSpacing.sm) {
                    Image(systemName: "creditcard")
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Text("Credit Balance")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        Text("0")
                            .h4()
                    }
                    Spacer()
                }
                .padding(LLSpacing.sm)
                .background(LLColors.muted.color(for: colorScheme))
                .cornerRadius(12)

                LLButton("Upgrade to Pro", style: .outline, size: .sm) {}
            }
        }
    }

    private var statGrid: some View {
        let summary = viewModel.summary
        let stats = [
            ("Total Tasks", "\(summary?.taskCount ?? 0)", "checklist"),
            ("Completed", "\(summary?.completedCount ?? 0)", "checkmark"),
            ("In Progress", "\(summary?.inProgressCount ?? 0)", "clock"),
            ("Projects", "\(summary?.projectCount ?? 0)", "folder")
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.md) {
            ForEach(stats, id: \.0) { title, value, icon in
                LLCard(style: .standard, padding: .md) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        HStack {
                            Text(title)
                                .captionText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            Spacer()
                            Image(systemName: icon)
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        Text(value)
                            .h3()
                    }
                }
            }
        }
    }

    private var recentTasksSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Your Recent Tasks")
                    .h4()
                Text("Showing \(min(viewModel.recentTasks.count, 5)) of \(viewModel.summary?.taskCount ?? 0) tasks")
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                if viewModel.recentTasks.isEmpty {
                    Text("No tasks yet.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                } else {
                    VStack(spacing: LLSpacing.sm) {
                        ForEach(viewModel.recentTasks) { task in
                            HStack(alignment: .top, spacing: LLSpacing.sm) {
                                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                    Text(task.title)
                                        .bodyText()
                                    if let description = task.description, !description.isEmpty {
                                        Text(description)
                                            .captionText()
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: LLSpacing.xs) {
                                    if let status = task.status {
                                        LLBadge(status.rawValue, variant: status == .completed ? .success : .outline, size: .sm)
                                    }
                                    if let priority = task.priority {
                                        LLBadge(priority.rawValue, variant: .outline, size: .sm)
                                    }
                                }
                            }
                            .padding(.vertical, LLSpacing.xs)
                            Divider()
                                .background(LLColors.muted.color(for: colorScheme))
                        }
                    }
                }
            }
        }
    }
}
