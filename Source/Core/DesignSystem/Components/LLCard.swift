//
//  LLCard.swift
//  TaskLuid
//

import SwiftUI

enum LLCardStyle {
    case standard
    case elevated
    case outlined
    case filled
}

enum LLCardPadding {
    case none
    case sm
    case md
    case lg
}

struct LLCard<Content: View>: View {
    let style: LLCardStyle
    let padding: LLCardPadding
    let onTap: (() -> Void)?
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: LLCardStyle = .standard,
        padding: LLCardPadding = .md,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        let card = content
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(LLSpacing.radiusLG)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)

        if let onTap = onTap {
            Button(action: onTap) { card }
                .buttonStyle(PlainButtonStyle())
        } else {
            card
        }
    }

    private var cardPadding: CGFloat {
        switch padding {
        case .none: return 0
        case .sm: return LLSpacing.sm
        case .md: return LLSpacing.lg
        case .lg: return LLSpacing.xl
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled, .standard, .elevated:
            return LLColors.card.color(for: colorScheme)
        case .outlined:
            return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .outlined, .standard:
            return LLColors.border.color(for: colorScheme)
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .outlined, .standard: return 1
        default: return 0
        }
    }

    private var shadowColor: Color {
        style == .elevated ? Color.black.opacity(0.08) : .clear
    }

    private var shadowRadius: CGFloat {
        style == .elevated ? 6 : 0
    }
}
