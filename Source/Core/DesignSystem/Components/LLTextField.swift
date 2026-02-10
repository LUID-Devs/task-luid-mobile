//
//  LLTextField.swift
//  TaskLuid
//

import SwiftUI

struct LLTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(title)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, LLSpacing.md)
                    .frame(height: LLSpacing.buttonHeightMD)
                    .background(LLColors.card.color(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                            .stroke(LLColors.input.color(for: colorScheme), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, LLSpacing.md)
                    .frame(height: LLSpacing.buttonHeightMD)
                    .background(LLColors.card.color(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                            .stroke(LLColors.input.color(for: colorScheme), lineWidth: 1)
                    )
            }
        }
    }
}
