//
//  FetchNearestMealListIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation

struct FetchNearestMealListIntent: AppIntent {
    static let title: LocalizedStringResource = "가장 가까운 식단 목록 조회"
    static let description = IntentDescription("현재 시각 기준으로 오늘 중식 또는 석식 메뉴 항목을 배열로 가져옵니다.")

    func perform() async throws -> some ReturnsValue<[String]> & ProvidesDialog {
        let (meal, mealType) = try AppGroupMealCache.resolveNearestMeal()
        let items = mealType == .lunch
            ? meal.sortedLunchItems.map(\.name)
            : meal.sortedDinnerItems.map(\.name)
        let menuList = items.joined(separator: ", ")
        return .result(value: items, dialog: "오늘 \(mealType.label) 식단은 \(menuList)입니다.")
    }
}
