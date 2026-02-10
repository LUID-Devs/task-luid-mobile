//
//  LLTypography.swift
//  TaskLuid
//

import SwiftUI

enum LLTypography {
    static func h1() -> Font { .system(size: 34, weight: .bold) }
    static func h2() -> Font { .system(size: 28, weight: .bold) }
    static func h3() -> Font { .system(size: 24, weight: .semibold) }
    static func h4() -> Font { .system(size: 20, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func bodySmall() -> Font { .system(size: 14, weight: .regular) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
}

extension Text {
    func h1() -> some View { self.font(LLTypography.h1()) }
    func h2() -> some View { self.font(LLTypography.h2()) }
    func h3() -> some View { self.font(LLTypography.h3()) }
    func h4() -> some View { self.font(LLTypography.h4()) }
    func bodyText() -> some View { self.font(LLTypography.body()) }
    func bodySmall() -> some View { self.font(LLTypography.bodySmall()) }
    func captionText() -> some View { self.font(LLTypography.caption()) }
}
