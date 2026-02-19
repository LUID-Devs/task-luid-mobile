//
//  TimelineViewModel.swift
//  TaskLuid
//

import Foundation

enum TimelineActivityType: String, CaseIterable, Identifiable {
    case all = "all"
    case taskCreated = "task_created"
    case taskCompleted = "task_completed"
    case projectCreated = "project_created"
    case projectUpdated = "project_updated"
    case commentAdded = "comment_added"
    case fileUploaded = "file_uploaded"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "All Activities"
        case .taskCreated:
            return "Task Created"
        case .taskCompleted:
            return "Task Completed"
        case .projectCreated:
            return "Project Created"
        case .commentAdded:
            return "Comments"
        case .fileUploaded:
            return "File Uploads"
        case .projectUpdated:
            return "Project Completed"
        }
    }

    var isTaskEvent: Bool {
        switch self {
        case .taskCreated, .taskCompleted:
            return true
        default:
            return false
        }
    }

    var isProjectEvent: Bool {
        switch self {
        case .projectCreated, .projectUpdated:
            return true
        default:
            return false
        }
    }
}

struct TimelineActivity: Identifiable {
    let id: String
    let type: TimelineActivityType
    let title: String
    let description: String
    let timestamp: Date
    let userName: String
}

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var filterType: TimelineActivityType = .all
    @Published var searchQuery: String = ""

    private let taskService = TaskService.shared
    private let projectService = ProjectService.shared
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

    func loadTimeline(userId: Int) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let tasksRequest = taskService.getTasksByUser(userId: userId)
            async let projectsRequest = projectService.getProjects()
            tasks = try await tasksRequest
            projects = try await projectsRequest
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var timelineActivities: [TimelineActivity] {
        let activities = buildActivities()
        let filtered = activities.filter { activity in
            if filterType != .all && activity.type != filterType { return false }
            if !searchQuery.isEmpty && !activity.description.lowercased().contains(searchQuery.lowercased()) {
                return false
            }
            return true
        }
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    var stats: (today: Int, thisWeek: Int, taskEvents: Int, projectEvents: Int) {
        let calendar = Calendar.current
        let today = timelineActivities.filter { calendar.isDateInToday($0.timestamp) }.count
        let thisWeek = timelineActivities.filter { calendar.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }.count
        let taskEvents = timelineActivities.filter { $0.type.isTaskEvent }.count
        let projectEvents = timelineActivities.filter { $0.type.isProjectEvent }.count
        return (today, thisWeek, taskEvents, projectEvents)
    }

    private func buildActivities() -> [TimelineActivity] {
        var activities: [TimelineActivity] = []

        for task in tasks {
            if let startDate = task.startDate, let parsed = parseDate(startDate) {
                activities.append(
                    TimelineActivity(
                        id: "task-created-\(task.id)",
                        type: .taskCreated,
                        title: "Task Created",
                        description: "Created task \"\(task.title)\"",
                        timestamp: parsed,
                        userName: task.author?.username ?? "Unknown User"
                    )
                )
            }

            if task.status == .completed, let dueDate = task.dueDate, let parsed = parseDate(dueDate) {
                activities.append(
                    TimelineActivity(
                        id: "task-completed-\(task.id)",
                        type: .taskCompleted,
                        title: "Task Completed",
                        description: "Completed task \"\(task.title)\"",
                        timestamp: parsed,
                        userName: task.assignee?.username ?? "Unknown User"
                    )
                )
            }

            task.comments?.forEach { comment in
                if let parsed = parseDate(comment.createdAt) {
                    let preview = truncate(comment.text, limit: 100)
                    activities.append(
                        TimelineActivity(
                            id: "comment-\(comment.id)",
                            type: .commentAdded,
                            title: "Comment Added",
                            description: "Commented on \"\(task.title)\": \(preview)",
                            timestamp: parsed,
                            userName: comment.user.username
                        )
                    )
                }
            }

            task.attachments?.forEach { attachment in
                let fileName = attachment.fileName ?? "file"
                activities.append(
                    TimelineActivity(
                        id: "attachment-\(attachment.id)",
                        type: .fileUploaded,
                        title: "File Uploaded",
                        description: "Uploaded \"\(fileName)\" to \"\(task.title)\"",
                        timestamp: Date(),
                        userName: attachment.uploadedBy.username
                    )
                )
            }
        }

        for project in projects {
            if let startDate = project.startDate, let parsed = parseDate(startDate) {
                activities.append(
                    TimelineActivity(
                        id: "project-created-\(project.id)",
                        type: .projectCreated,
                        title: "Project Created",
                        description: "Created project \"\(project.name)\"",
                        timestamp: parsed,
                        userName: "Workspace"
                    )
                )
            }

            if let endDate = project.endDate, let parsed = parseDate(endDate) {
                activities.append(
                    TimelineActivity(
                        id: "project-completed-\(project.id)",
                        type: .projectUpdated,
                        title: "Project Completed",
                        description: "Completed project \"\(project.name)\"",
                        timestamp: parsed,
                        userName: "Workspace"
                    )
                )
            }
        }

        return activities
    }

    private func parseDate(_ value: String) -> Date? {
        if let parsed = isoFormatter.date(from: value) {
            return parsed
        }
        return isoFormatterNoFraction.date(from: value)
    }

    private func truncate(_ value: String, limit: Int) -> String {
        guard value.count > limit else { return value }
        let endIndex = value.index(value.startIndex, offsetBy: limit)
        return String(value[..<endIndex]) + "..."
    }
}
