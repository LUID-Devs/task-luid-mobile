//
//  LLSpacing.swift
//  TaskLuid
//

import SwiftUI

enum LLSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64

    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 8
    static let radiusLG: CGFloat = 10
    static let radiusXL: CGFloat = 14

    static let buttonHeightSM: CGFloat = 36
    static let buttonHeightMD: CGFloat = 44
    static let buttonHeightLG: CGFloat = 52
}

extension View {
    func screenPadding() -> some View {
        self.padding(.horizontal, LLSpacing.md).padding(.vertical, LLSpacing.md)
    }

    func minTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}
