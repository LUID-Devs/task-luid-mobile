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
                .foregroundColor(LLColors.destructive.color(for: colorScheme))
            Text(message)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.destructive.color(for: colorScheme))
        }
        .padding(LLSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LLColors.card.color(for: colorScheme))
        .cornerRadius(LLSpacing.radiusMD)
    }
}
