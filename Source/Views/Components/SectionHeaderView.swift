//
//  SectionHeaderView.swift
//  TaskLuid
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(title)
                .h3()
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
            if let subtitle = subtitle {
                Text(subtitle)
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
