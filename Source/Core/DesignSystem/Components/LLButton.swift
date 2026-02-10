//
//  LLButton.swift
//  TaskLuid
//

import SwiftUI

enum LLButtonStyle {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

enum LLButtonSize {
    case sm
    case md
    case lg
}

struct LLButton: View {
    let title: String?
    let icon: Image?
    let style: LLButtonStyle
    let size: LLButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let fullWidth: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        _ title: String? = nil,
        icon: Image? = nil,
        style: LLButtonStyle = .primary,
        size: LLButtonSize = .md,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LLSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let icon = icon {
                    icon
                }

                if let title = title {
                    Text(title)
                        .font(LLTypography.body())
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, LLSpacing.lg)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(LLSpacing.radiusMD)
        }
        .disabled(isDisabled || isLoading)
    }

    private var height: CGFloat {
        switch size {
        case .sm: return LLSpacing.buttonHeightSM
        case .md: return LLSpacing.buttonHeightMD
        case .lg: return LLSpacing.buttonHeightLG
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return LLColors.primaryForeground.color(for: colorScheme)
        case .destructive:
            return LLColors.destructiveForeground.color(for: colorScheme)
        case .secondary, .outline, .ghost:
            return LLColors.foreground.color(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return LLColors.primary.color(for: colorScheme)
        case .secondary:
            return LLColors.secondary.color(for: colorScheme)
        case .outline, .ghost:
            return .clear
        case .destructive:
            return LLColors.destructive.color(for: colorScheme)
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return LLColors.border.color(for: colorScheme)
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        style == .outline ? 1 : 0
    }
}
