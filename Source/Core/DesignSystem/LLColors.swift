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
        light: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0))
    )

    static let primaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let secondary = ColorSet(
        light: Color(oklch: OKLCH(l: 0.97, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.269, c: 0, h: 0))
    )

    static let secondaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    static let accent = secondary
    static let accentForeground = secondaryForeground

    static let background = ColorSet(
        light: Color(oklch: OKLCH(l: 1, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0))
    )

    static let foreground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    static let card = ColorSet(
        light: Color(oklch: OKLCH(l: 1, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let cardForeground = foreground

    static let muted = ColorSet(
        light: Color(oklch: OKLCH(l: 0.97, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.269, c: 0, h: 0))
    )

    static let mutedForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.556, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.708, c: 0, h: 0))
    )

    static let popover = card
    static let popoverForeground = foreground

    static let destructive = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.9, c: 0, h: 0))
    )

    static let destructiveForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let success = ColorSet(
        light: Color(oklch: OKLCH(l: 0.24, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.82, c: 0, h: 0))
    )

    static let successForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let warning = ColorSet(
        light: Color(oklch: OKLCH(l: 0.32, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0, h: 0))
    )

    static let warningForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let info = ColorSet(
        light: Color(oklch: OKLCH(l: 0.4, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.6, c: 0, h: 0))
    )

    static let infoForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let border = ColorSet(
        light: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0)),
        dark: Color(white: 1.0, opacity: 0.1)
    )

    static let input = ColorSet(
        light: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0)),
        dark: Color(white: 1.0, opacity: 0.15)
    )

    static let ring = ColorSet(
        light: Color(oklch: OKLCH(l: 0.708, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.556, c: 0, h: 0))
    )
}
