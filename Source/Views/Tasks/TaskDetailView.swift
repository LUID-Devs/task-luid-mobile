//
//  TaskDetailView.swift
//  TaskLuid
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem

    @State private var selectedStatus: TaskStatus?
    @State private var isUpdating = false
    @State private var errorMessage: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text(task.title)
                            .h3()
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        HStack(spacing: LLSpacing.sm) {
                            if let priority = task.priority {
                                LLBadge(priority.rawValue, variant: .outline, size: .sm)
                            }
                            if let status = task.status {
                                LLBadge(status.rawValue, variant: status == .completed ? .success : .default, size: .sm)
                            }
                        }
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Details")
                            .h4()
                        detailRow(label: "Priority", value: task.priority?.rawValue ?? "-")
                        detailRow(label: "Status", value: task.status?.rawValue ?? "-")
                        detailRow(label: "Due", value: task.dueDate ?? "-")
                        detailRow(label: "Start", value: task.startDate ?? "-")
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("People")
                            .h4()
                        detailRow(label: "Assignee", value: task.assignee?.username ?? "Unassigned")
                        detailRow(label: "Author", value: task.author?.username ?? "-")
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Update Status")
                            .h4()

                        Picker("Status", selection: $selectedStatus) {
                            Text("None").tag(TaskStatus?.none)
                            ForEach(TaskStatus.allCases) { status in
                                Text(status.rawValue).tag(TaskStatus?.some(status))
                            }
                        }
                        .pickerStyle(.menu)

                        if let errorMessage = errorMessage {
                            InlineErrorView(message: errorMessage)
                        }

                        LLButton("Save", style: .primary, isLoading: isUpdating, fullWidth: true) {
                            Task { await updateStatus() }
                        }
                    }
                }

                commentsSection
                attachmentsSection
            }
            .screenPadding()
        }
        .navigationTitle("Task")
        .onAppear {
            selectedStatus = task.status
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Spacer()
            Text(value)
                .bodySmall()
        }
    }

    private func updateStatus() async {
        guard let selectedStatus else { return }
        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            _ = try await TaskService.shared.updateTaskStatus(taskId: task.id, status: selectedStatus)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var commentsSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Comments")
                    .h4()
                if let comments = task.comments, !comments.isEmpty {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(comment.user.username)
                                .bodySmall()
                            Text(comment.text)
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .padding(.vertical, LLSpacing.xs)
                    }
                } else {
                    Text("No comments yet.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }

    private var attachmentsSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Attachments")
                    .h4()
                if let attachments = task.attachments, !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        HStack {
                            Image(systemName: "paperclip")
                            Text(attachment.fileName ?? "Attachment")
                                .bodyText()
                            Spacer()
                        }
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                } else {
                    Text("No attachments.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }
}
