//
//  LLBackgroundView.swift
//  TaskLuid
//

import SwiftUI

struct LLBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LLColors.background.color(for: colorScheme),
                    LLColors.card.color(for: colorScheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(LLColors.primary.color(for: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.18))
                .frame(width: 360, height: 360)
                .offset(x: 160, y: -220)

            RoundedRectangle(cornerRadius: 60)
                .fill(LLColors.secondary.color(for: colorScheme).opacity(colorScheme == .dark ? 0.16 : 0.28))
                .frame(width: 280, height: 220)
                .rotationEffect(.degrees(-12))
                .offset(x: -140, y: 220)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appBackground() -> some View {
        background(LLBackgroundView())
    }
}
