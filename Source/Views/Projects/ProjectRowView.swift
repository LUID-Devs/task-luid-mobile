//
//  ProjectRowView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectRowView: View {
    let project: Project

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Text(project.name)
                            .h4()
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        if let description = project.description, !description.isEmpty {
                            Text(description)
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    if project.isFavorited == true {
                        Image(systemName: "star.fill")
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                }

                if let stats = project.statistics {
                    HStack(spacing: LLSpacing.md) {
                        LLBadge("\(stats.totalTasks) tasks", variant: .outline, size: .sm)
                        LLBadge("\(stats.completedTasks) done", variant: .success, size: .sm)
                    }
                }
            }
        }
    }
}
