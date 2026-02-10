//
//  LLLoadingView.swift
//  TaskLuid
//

import SwiftUI

struct LLLoadingView: View {
    let title: String

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String = "Loading...") {
        self.title = title
    }

    var body: some View {
        VStack(spacing: LLSpacing.sm) {
            ProgressView()
            Text(title)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LLSpacing.lg)
    }
}
