//
//  View+PlatformChrome.swift
//  Shared
//

import SwiftUI

extension View {
    /// iOS에서만 inline navigation bar title mode를 적용한다.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// iOS sheet detent. macOS에서는 무시.
    @ViewBuilder
    func platformPresentationDetents(_ detents: Set<PresentationDetent>) -> some View {
        #if os(iOS)
        presentationDetents(detents)
        #else
        self
        #endif
    }

    /// iOS sheet 상단 드래그 인디케이터. macOS에서는 무시.
    @ViewBuilder
    func platformPresentationDragIndicator(_ visibility: Visibility = .visible) -> some View {
        #if os(iOS)
        presentationDragIndicator(visibility)
        #else
        self
        #endif
    }

    /// 드래그로 닫을 수 있는 iOS sheet — detent + drag indicator.
    @ViewBuilder
    func dismissibleSheetChrome(detents: Set<PresentationDetent>) -> some View {
        #if os(iOS)
        platformPresentationDetents(detents)
            .platformPresentationDragIndicator()
        #else
        self
        #endif
    }

    /// 드래그 dismiss를 막는 iOS sheet — detent + interactiveDismissDisabled.
    @ViewBuilder
    func lockedSheetChrome(detents: Set<PresentationDetent>) -> some View {
        #if os(iOS)
        platformPresentationDetents(detents)
            .interactiveDismissDisabled()
        #else
        self
        #endif
    }

    @ViewBuilder
    func prominentShareButtonStyle() -> some View {
        #if os(iOS)
        buttonStyle(.glassProminent)
        #else
        buttonStyle(.borderedProminent)
        #endif
    }
}
