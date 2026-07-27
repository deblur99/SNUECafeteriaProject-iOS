//
//  View+GlassCompat.swift
//  SNUECafeteriaProject
//

import SwiftUI

extension View {
    /// iOS 26+ glass / glassProminent. 하위 버전은 bordered / borderedProminent으로 대체한다.
    @ViewBuilder
    func glassCompatButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if prominent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}
