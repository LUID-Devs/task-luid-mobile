//
//  InlineErrorView.swift
//  TaskLuid
//

import SwiftUI

struct InlineErrorView: View {
    let message: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(LLColors.destructive.color(for: colorScheme))
            Text(message)
                .font(LLTypography.bodySmall())
                .foregroundStyle(LLColors.destructive.color(for: colorScheme))
        }
        .padding(LLSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.destructive.color(for: colorScheme).opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .stroke(LLColors.destructive.color(for: colorScheme).opacity(0.35), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: LLSpacing.radiusMD))
    }
}
