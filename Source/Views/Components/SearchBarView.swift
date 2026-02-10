//
//  SearchBarView.swift
//  TaskLuid
//

import SwiftUI

struct SearchBarView: View {
    let placeholder: String
    @Binding var text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
        .padding(.horizontal, LLSpacing.md)
        .frame(height: LLSpacing.buttonHeightMD)
        .background(LLColors.card.color(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
        )
    }
}
