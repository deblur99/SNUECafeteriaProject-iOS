//
//  Color+GroupedBackground.swift
//  Shared
//

import SwiftUI

extension Color {
    /// 시스템 그룹드 배경 — 플랫폼별 시맨틱 컬러.
    nonisolated static var groupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif os(watchOS)
        Color.black
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    nonisolated static var secondaryGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif os(watchOS)
        Color(white: 0.12)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    nonisolated static var tertiaryLabelColor: Color {
        #if os(macOS)
        Color(nsColor: .tertiaryLabelColor)
        #elseif os(watchOS)
        Color.secondary
        #else
        Color(uiColor: .tertiaryLabel)
        #endif
    }
}
