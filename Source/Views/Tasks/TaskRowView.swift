//
//  TaskRowView.swift
//  TaskLuid
//

import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let showsSelection: Bool
    let isSelected: Bool
    let onSelectToggle: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(
        task: TaskItem,
        showsSelection: Bool = false,
        isSelected: Bool = false,
        onSelectToggle: (() -> Void)? = nil
    ) {
        self.task = task
        self.showsSelection = showsSelection
        self.isSelected = isSelected
        self.onSelectToggle = onSelectToggle
    }

    var body: some View {
        LLCard(style: .standard) {
            HStack(alignment: .top, spacing: LLSpacing.sm) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusAccent)
                    .frame(width: 4)

                if showsSelection {
                    Button {
                        onSelectToggle?()
                    } label: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? LLColors.foreground.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    HStack(alignment: .top, spacing: LLSpacing.sm) {
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
                        if let dueDate = formattedDueDate() {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text("Due \(dueDate)")
                            }
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    private var statusAccent: Color {
        if task.status == .completed {
            return LLColors.success.color(for: colorScheme)
        }
        return LLColors.info.color(for: colorScheme)
    }

    private func formattedDueDate() -> String? {
        guard let date = parseDate(task.dueDate) else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }
}
