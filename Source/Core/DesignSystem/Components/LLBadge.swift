//
//  LLBadge.swift
//  TaskLuid
//

import SwiftUI

enum LLBadgeVariant {
    case `default`
    case success
    case error
    case warning
    case info
    case outline
}

enum LLBadgeSize {
    case sm
    case md
    case lg
}

struct LLBadge: View {
    let title: String
    let icon: Image?
    let variant: LLBadgeVariant
    let size: LLBadgeSize

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String, icon: Image? = nil, variant: LLBadgeVariant = .default, size: LLBadgeSize = .md) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
    }

    var body: some View {
        HStack(spacing: LLSpacing.xs) {
            if let icon = icon {
                icon
            }
            Text(title)
                .font(font)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .foregroundStyle(foregroundColor)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                .stroke(borderColor, lineWidth: variant == .outline ? 1 : 0)
        )
        .clipShape(.rect(cornerRadius: LLSpacing.radiusSM))
    }

    private var font: Font {
        switch size {
        case .sm: return LLTypography.caption()
        case .md: return LLTypography.bodySmall()
        case .lg: return LLTypography.body()
        }
    }

    private var horizontalPadding: CGFloat {
        size == .sm ? LLSpacing.sm : LLSpacing.md
    }

    private var verticalPadding: CGFloat {
        size == .sm ? LLSpacing.xs : LLSpacing.sm
    }

    private var foregroundColor: Color {
        switch variant {
        case .success: return LLColors.successForeground.color(for: colorScheme)
        case .error: return LLColors.destructiveForeground.color(for: colorScheme)
        case .warning: return LLColors.warningForeground.color(for: colorScheme)
        case .info: return LLColors.infoForeground.color(for: colorScheme)
        case .outline: return LLColors.foreground.color(for: colorScheme)
        case .default: return LLColors.foreground.color(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .outline:
            return .clear
        case .success:
            return LLColors.success.color(for: colorScheme)
        case .error:
            return LLColors.destructive.color(for: colorScheme)
        case .warning:
            return LLColors.warning.color(for: colorScheme)
        case .info:
            return LLColors.info.color(for: colorScheme)
        default:
            return LLColors.muted.color(for: colorScheme)
        }
    }

    private var borderColor: Color {
        variant == .outline ? LLColors.border.color(for: colorScheme) : .clear
    }
}
