//
//  TimelineView.swift
//  TaskLuid
//

import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Timeline", subtitle: "Track upcoming due dates.")

                if viewModel.isLoading {
                    LLLoadingView("Loading timeline...")
                } else if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                } else if groupedTasks.isEmpty {
                    LLEmptyState(
                        icon: "calendar",
                        title: "No upcoming tasks",
                        message: "Tasks with due dates will show here."
                    )
                } else {
                    ForEach(groupedTasks.keys.sorted(), id: \.self) { key in
                        let tasks = groupedTasks[key] ?? []
                        LLCard(style: .standard) {
                            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                                Text(key)
                                    .h4()
                                ForEach(tasks) { task in
                                    HStack(alignment: .top, spacing: LLSpacing.sm) {
                                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                            Text(task.title)
                                                .bodyText()
                                            if let dueDate = task.dueDate {
                                                Text("Due \(dueDate)")
                                                    .captionText()
                                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                            }
                                        }
                                        Spacer()
                                        if let status = task.status {
                                            LLBadge(status.rawValue, variant: status == .completed ? .success : .outline, size: .sm)
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
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
        .task(id: authViewModel.user?.userId) {
            if let userId = authViewModel.user?.userId {
                await viewModel.loadTasks(userId: userId)
            }
        }
    }

    private var groupedTasks: [String: [TaskItem]] {
        let tasksWithDate = viewModel.tasks.filter { $0.dueDate != nil }
        let mapped = tasksWithDate.compactMap { task -> (String, TaskItem)? in
            guard let dueDate = task.dueDate else { return nil }
            if let parsed = isoFormatter.date(from: dueDate) ?? isoFormatterNoFraction.date(from: dueDate) {
                let key = monthFormatter.string(from: parsed)
                return (key, task)
            }
            return ("Unscheduled", task)
        }
        return Dictionary(grouping: mapped, by: { $0.0 }).mapValues { $0.map { $0.1 } }
    }
}
