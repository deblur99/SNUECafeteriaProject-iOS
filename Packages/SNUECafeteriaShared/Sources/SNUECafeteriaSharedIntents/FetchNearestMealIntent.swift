//
//  FetchNearestMealIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation
import SwiftUI
import SNUECafeteriaShared

public struct FetchNearestMealImageIntent: AppIntent {
    public init() {}

    public static let title: LocalizedStringResource = "가장 가까운 식단 조회 (이미지)"
    public static let description = IntentDescription("현재 시각 기준으로 오늘 중식 또는 석식 메뉴를 이미지로 가져옵니다.")

    public func perform() async throws -> some ReturnsValue<MealEntity> & ProvidesDialog & ShowsSnippetView {
        let (meal, mealType) = try AppGroupMealCache.resolveNearestMeal()
        let entity = MealEntity(from: meal)
        
        let snippetView = await NearestMealSnippetView(entity: entity, mealType: mealType)
        return .result(value: entity, dialog: "오늘 \(mealType.label) 식단입니다.") {
            snippetView
        }
    }
}
