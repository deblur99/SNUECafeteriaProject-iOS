//
//  MealType.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

nonisolated enum MealType: String, Codable, CaseIterable {
    case lunch
    case dinner

    var label: String { self == .lunch ? "중식" : "석식" }

    var color: Color { .mealColor(for: self) }
}

/// 중식·석식 원형 배지 라벨 — Dynamic Type와 무관한 고정 크기.
nonisolated enum MealTypeBannerStyle {
    /// iOS 설정 > 텍스트 크기 '중간'에서 subheadline에 해당하는 pt.
    private static let circleLabelPointSize: CGFloat = {
        #if os(iOS)
        UIFont.preferredFont(
            forTextStyle: .subheadline,
            compatibleWith: UITraitCollection(
                preferredContentSizeCategory: .large
            )
        ).pointSize
        #else
        15
        #endif
    }()

    static var circleLabelFont: Font {
        .system(size: circleLabelPointSize, weight: .bold, design: .rounded)
    }
}
