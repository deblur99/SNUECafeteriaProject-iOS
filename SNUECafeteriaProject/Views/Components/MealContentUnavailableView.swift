//
//  MealContentUnavailableView.swift
//  SNUECafeteriaProject
//

import SwiftUI

/// 플랫폼별 빈 식단 상태.
/// macOS `ContentUnavailableView`는 좁은 다크 카드 배경을 그려 화면 배경과 어긋나므로
/// Mac에서는 동일 레이아웃의 투명 배경 커스텀 뷰를 쓴다.
struct MealContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: String
    var fillsParent: Bool = true
    var compact: Bool = false

    var body: some View {
        #if os(macOS)
        macBody
        #else
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .modifier(UnavailableFrame(fillsParent: fillsParent))
        #endif
    }

    #if os(macOS)
    private var macBody: some View {
        VStack(spacing: compact ? 8 : 12) {
            Image(systemName: systemImage)
                .font(compact ? .title2 : .system(size: 48, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            Text(title)
                .font(compact ? .subheadline.weight(.semibold) : .title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(description)
                .font(compact ? .footnote : .subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        // leading 부모(카드/Grid) 안에서도 가로 중앙 — ContentUnavailableView와 동일
        .frame(
            maxWidth: .infinity,
            maxHeight: fillsParent ? .infinity : nil,
            alignment: .center
        )
        .padding(compact ? 8 : 24)
        .background(Color.clear)
    }
    #endif
}

private struct UnavailableFrame: ViewModifier {
    let fillsParent: Bool

    func body(content: Content) -> some View {
        if fillsParent {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}
