//
//  DashboardView.swift
//  TaskLuid
//

import SwiftUI
import Charts

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
                        heroCard
                        statGrid
                        planCard
                        recentTasksSection
                        chartsGrid
                    }
                    .screenPadding()
                }
                .background(dashboardBackground)
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
            Text("Dashboard")
                .h2()
        }
    }

    private var heroCard: some View {
        let username = authViewModel.user?.username ?? "User"
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let dateLabel = formatter.string(from: Date())

        return ZStack {
            LinearGradient(
                colors: [
                    LLColors.muted.color(for: colorScheme),
                    LLColors.card.color(for: colorScheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(colorScheme == .dark ? 0.6 : 1.0)

            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack {
                    Text(dateLabel.uppercased())
                        .captionText()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    Spacer()
                    LLBadge("Active", variant: .outline, size: .sm)
                }
                Text("Welcome back, \(username)")
                    .h3()
                Text("You have \(viewModel.recentTasks.count) tasks in motion today.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(LLSpacing.lg)
        }
        .cornerRadius(LLSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
        )
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
                            Circle()
                                .fill(LLColors.muted.color(for: colorScheme))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: icon)
                                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                                )
                            Spacer()
                        }
                        Text(value)
                            .h3()
                        Text(title)
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            }
        }
    }

    private var recentTasksSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Recent Tasks")
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

    private var chartsGrid: some View {
        VStack(spacing: LLSpacing.md) {
            priorityDistributionCard
            projectStatusCard
        }
    }

    private var priorityDistributionCard: some View {
        let data = taskPriorityDistribution()
        return LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "flag")
                    Text("Task Priority Distribution")
                        .h4()
                }
                if data.isEmpty {
                    Text("No tasks assigned to you yet.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Priority", item.name)
                        )
                        .foregroundStyle(LLColors.foreground.color(for: colorScheme))
                    }
                    .frame(height: 220)
                }
            }
        }
    }

    private var projectStatusCard: some View {
        let data = projectStatusDistribution()
        return LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "briefcase")
                    Text("Project Status Overview")
                        .h4()
                }
                if data.isEmpty {
                    Text("No projects available.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Status", item.name)
                        )
                        .foregroundStyle(LLColors.mutedForeground.color(for: colorScheme))
                    }
                    .frame(height: 220)
                }
            }
        }
    }

    private func taskPriorityDistribution() -> [ChartItem] {
        let tasks = viewModel.allTasks
        guard !tasks.isEmpty else { return [] }
        return TaskPriority.allCases.map { priority in
            let count = tasks.filter { $0.priority == priority }.count
            return ChartItem(name: priority.rawValue, count: count)
        }
    }

    private func projectStatusDistribution() -> [ChartItem] {
        let projects = viewModel.allProjects
        guard !projects.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for project in projects {
            let status = project.archived == true ? "Archived" : (project.statistics?.status ?? "Active")
            counts[status, default: 0] += 1
        }
        return counts
            .map { ChartItem(name: $0.key, count: $0.value) }
            .sorted { $0.name < $1.name }
    }

    private struct ChartItem: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    private var dashboardBackground: some View {
        LinearGradient(
            colors: [
                LLColors.background.color(for: colorScheme),
                LLColors.muted.color(for: colorScheme)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
