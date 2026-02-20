//
//  LLEmptyState.swift
//  TaskLuid
//

import SwiftUI

enum LLEmptyStateStyle {
    case standard
    case minimal
    case feature
}

struct LLEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let style: LLEmptyStateStyle

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: LLEmptyStateStyle = .standard
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }

    var body: some View {
        VStack(spacing: LLSpacing.md) {
            Image(systemName: icon)
                .font(style == .feature ? .system(size: 48) : .system(size: 32))
                .foregroundStyle(LLColors.mutedForeground.color(for: colorScheme))

            Text(title)
                .font(style == .feature ? LLTypography.h3() : LLTypography.h4())
                .foregroundStyle(LLColors.foreground.color(for: colorScheme))

            Text(message)
                .font(LLTypography.bodySmall())
                .foregroundStyle(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                LLButton(actionTitle, style: .primary, size: .md, fullWidth: false, action: action)
            }
        }
        .padding(LLSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: LLSpacing.radiusLG))
    }
}
