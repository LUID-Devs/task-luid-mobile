//
//  TimelineView.swift
//  TaskLuid
//

import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Activity Timeline", subtitle: "Track activity across your projects and tasks.")

                if viewModel.isLoading {
                    LLLoadingView("Loading activity timeline...")
                } else if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                } else {
                    statsSection
                    filterSection
                    timelineSection
                }
            }
            .screenPadding()
        }
        .appBackground()
        .task(id: authViewModel.user?.userId) {
            if let userId = authViewModel.user?.userId {
                await viewModel.loadTimeline(userId: userId)
            }
        }
    }

    private var statsSection: some View {
        let stats = viewModel.stats
        return LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Activity Snapshot")
                    .h4()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.sm) {
                    timelineStatCard(title: "Today", value: "\(stats.today)")
                    timelineStatCard(title: "This Week", value: "\(stats.thisWeek)")
                    timelineStatCard(title: "Task Events", value: "\(stats.taskEvents)")
                    timelineStatCard(title: "Project Events", value: "\(stats.projectEvents)")
                }
            }
        }
    }

    private var filterSection: some View {
        LLCard(style: .standard) {
            VStack(spacing: LLSpacing.sm) {
                SearchBarView(placeholder: "Search activities", text: $viewModel.searchQuery)
                HStack {
                    Text("Filter")
                        .captionText()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    Spacer()
                    Picker("Filter", selection: $viewModel.filterType) {
                        ForEach(TimelineActivityType.allCases) { option in
                            if option != .projectUpdated {
                                Text(option.displayName).tag(option)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }

    private var timelineSection: some View {
        let groups = groupActivities(viewModel.timelineActivities)
        return VStack(spacing: LLSpacing.md) {
            if groups.isEmpty {
                LLEmptyState(
                    icon: "sparkles",
                    title: "No recent activity",
                    message: "Start creating tasks and projects to see your activity timeline."
                )
            } else {
                ForEach(groups) { group in
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            HStack {
                                Text(group.title)
                                    .h4()
                                Spacer()
                                Text("\(group.activities.count) activities")
                                    .captionText()
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                            ForEach(group.activities) { activity in
                                activityRow(activity)
                                if activity.id != group.activities.last?.id {
                                    Divider()
                                        .background(LLColors.muted.color(for: colorScheme))
                                }
                            }
                        }
                    }
                }
            }
            if !viewModel.timelineActivities.isEmpty {
                Text("Showing \(viewModel.timelineActivities.count) recent activities")
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private func timelineStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(value)
                .h3()
            Text(title)
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, LLSpacing.sm)
        .padding(.horizontal, LLSpacing.md)
        .background(LLColors.muted.color(for: colorScheme))
        .cornerRadius(LLSpacing.radiusMD)
    }

    private func activityRow(_ activity: TimelineActivity) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(activity.title)
                .bodyText()
            Text(activity.description)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            HStack(spacing: LLSpacing.xs) {
                Text(activity.userName)
                Text("•")
                Text(relativeDate(activity.timestamp))
            }
            .font(LLTypography.caption())
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding(.vertical, LLSpacing.xs)
    }

    private func groupActivities(_ activities: [TimelineActivity]) -> [TimelineGroup] {
        var grouped: [String: [TimelineActivity]] = [:]
        for activity in activities {
            let title = groupTitle(for: activity.timestamp)
            grouped[title, default: []].append(activity)
        }
        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            guard let leftDate = parseGroupDate(lhs), let rightDate = parseGroupDate(rhs) else {
                return lhs > rhs
            }
            return leftDate > rightDate
        }
        return sortedKeys.map { key in
            let items = grouped[key] ?? []
            return TimelineGroup(id: key, title: key, activities: items)
        }
    }

    private func groupTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        }
        return dayFormatter.string(from: date)
    }

    private func parseGroupDate(_ value: String) -> Date? {
        if value == "Today" || value == "Yesterday" || value == "This Week" {
            return Date()
        }
        return dayFormatter.date(from: value)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct TimelineGroup: Identifiable {
    let id: String
    let title: String
    let activities: [TimelineActivity]
}
