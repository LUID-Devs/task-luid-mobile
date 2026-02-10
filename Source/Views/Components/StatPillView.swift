//
//  StatPillView.swift
//  TaskLuid
//

import SwiftUI

struct StatPillView: View {
    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.sm) {
            Text(value)
                .font(LLTypography.h4())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
            Text(title)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding(.horizontal, LLSpacing.md)
        .padding(.vertical, LLSpacing.sm)
        .background(LLColors.muted.color(for: colorScheme))
        .cornerRadius(LLSpacing.radiusLG)
    }
}
