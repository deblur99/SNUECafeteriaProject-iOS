//
//  FetchNearestMealIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation
import SwiftUI

struct FetchNearestMealIntent: AppIntent {
    static let title: LocalizedStringResource = "가장 가까운 식단 조회"
    static let description = IntentDescription("현재 시각 기준으로 오늘 중식 또는 석식 메뉴를 가져옵니다.")

    func perform() async throws -> some ReturnsValue<MealEntity> & ProvidesDialog & ShowsSnippetView {
        guard let (meal, mealType) = AppGroupMealCache.nearestMeal() else {
            throw AppIntentError.noMealFound
        }
        let entity = MealEntity(from: meal)
        return .result(value: entity, dialog: "오늘 \(mealType.label) 식단입니다.") {
            NearestMealSnippetView(entity: entity, mealType: mealType)
        }
    }
}
