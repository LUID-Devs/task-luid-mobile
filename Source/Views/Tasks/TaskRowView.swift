//
//  TaskRowView.swift
//  TaskLuid
//

import SwiftUI

struct TaskRowView: View {
    let task: TaskItem

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Text(task.title)
                            .h4()
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    if let priority = task.priority {
                        LLBadge(priority.rawValue, variant: .outline, size: .sm)
                    }
                }

                HStack(spacing: LLSpacing.sm) {
                    if let status = task.status {
                        LLBadge(status.rawValue, variant: status == .completed ? .success : .default, size: .sm)
                    }
                    if let dueDate = task.dueDate, !dueDate.isEmpty {
                        Text("Due \(dueDate)")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            }
        }
    }
}
