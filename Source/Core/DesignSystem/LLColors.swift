//
//  LLColors.swift
//  TaskLuid
//

import SwiftUI

struct ColorSet {
    let light: Color
    let dark: Color

    func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }
}

struct OKLCH {
    let l: Double
    let c: Double
    let h: Double
}

extension Color {
    init(oklch: OKLCH) {
        let a = oklch.c * cos(oklch.h * .pi / 180)
        let b = oklch.c * sin(oklch.h * .pi / 180)

        let fy = (oklch.l + 0.16) / 1.16
        let fx = a / 500 + fy
        let fz = fy - b / 200

        let xr = fx > 0.206897 ? pow(fx, 3) : (fx - 0.137931) / 7.787
        let yr = fy > 0.206897 ? pow(fy, 3) : (fy - 0.137931) / 7.787
        let zr = fz > 0.206897 ? pow(fz, 3) : (fz - 0.137931) / 7.787

        let x = xr * 0.95047
        let y = yr * 1.0
        let z = zr * 1.08883

        var r = x * 3.2406 + y * -1.5372 + z * -0.4986
        var g = x * -0.9689 + y * 1.8758 + z * 0.0415
        var bl = x * 0.0557 + y * -0.2040 + z * 1.0570

        r = r > 0.0031308 ? 1.055 * pow(r, 1/2.4) - 0.055 : 12.92 * r
        g = g > 0.0031308 ? 1.055 * pow(g, 1/2.4) - 0.055 : 12.92 * g
        bl = bl > 0.0031308 ? 1.055 * pow(bl, 1/2.4) - 0.055 : 12.92 * bl

        r = max(0, min(1, r))
        g = max(0, min(1, g))
        bl = max(0, min(1, bl))

        self.init(red: r, green: g, blue: bl)
    }
}

enum LLColors {
    static let primary = ColorSet(
        light: Color(oklch: OKLCH(l: 0.62, c: 0.16, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0.16, h: 255))
    )

    static let primaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.98, c: 0.02, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.14, c: 0.03, h: 255))
    )

    static let secondary = ColorSet(
        light: Color(oklch: OKLCH(l: 0.95, c: 0.02, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.25, c: 0.02, h: 255))
    )

    static let secondaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.18, c: 0.02, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.96, c: 0.01, h: 255))
    )

    static let accent = secondary
    static let accentForeground = secondaryForeground

    static let background = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0.01, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.13, c: 0.01, h: 255))
    )

    static let foreground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.18, c: 0.01, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.96, c: 0.01, h: 255))
    )

    static let card = ColorSet(
        light: Color(oklch: OKLCH(l: 0.995, c: 0.01, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.18, c: 0.01, h: 255))
    )

    static let cardForeground = foreground

    static let muted = ColorSet(
        light: Color(oklch: OKLCH(l: 0.93, c: 0.01, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.24, c: 0.01, h: 255))
    )

    static let mutedForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.5, c: 0.01, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0.01, h: 255))
    )

    static let popover = card
    static let popoverForeground = foreground

    static let destructive = ColorSet(
        light: Color(oklch: OKLCH(l: 0.58, c: 0.22, h: 25)),
        dark: Color(oklch: OKLCH(l: 0.66, c: 0.22, h: 25))
    )

    static let destructiveForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.98, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.98, c: 0, h: 0))
    )

    static let success = ColorSet(
        light: Color(oklch: OKLCH(l: 0.62, c: 0.17, h: 145)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0.16, h: 145))
    )

    static let successForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.98, c: 0.01, h: 145)),
        dark: Color(oklch: OKLCH(l: 0.14, c: 0.02, h: 145))
    )

    static let warning = ColorSet(
        light: Color(oklch: OKLCH(l: 0.75, c: 0.16, h: 80)),
        dark: Color(oklch: OKLCH(l: 0.78, c: 0.16, h: 80))
    )

    static let warningForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.25, c: 0.02, h: 80)),
        dark: Color(oklch: OKLCH(l: 0.2, c: 0.02, h: 80))
    )

    static let info = ColorSet(
        light: Color(oklch: OKLCH(l: 0.62, c: 0.14, h: 220)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0.12, h: 220))
    )

    static let infoForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.98, c: 0.01, h: 220)),
        dark: Color(oklch: OKLCH(l: 0.16, c: 0.02, h: 220))
    )

    static let border = ColorSet(
        light: Color(oklch: OKLCH(l: 0.9, c: 0.01, h: 255)),
        dark: Color(white: 1.0, opacity: 0.1)
    )

    static let input = ColorSet(
        light: Color(oklch: OKLCH(l: 0.88, c: 0.01, h: 255)),
        dark: Color(white: 1.0, opacity: 0.12)
    )

    static let ring = ColorSet(
        light: Color(oklch: OKLCH(l: 0.62, c: 0.1, h: 255)),
        dark: Color(oklch: OKLCH(l: 0.55, c: 0.12, h: 255))
    )
}
