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

    @ViewBuilder
    func prominentShareButtonStyle() -> some View {
        #if os(iOS)
        buttonStyle(.glassProminent)
        #else
        buttonStyle(.borderedProminent)
        #endif
    }
}
