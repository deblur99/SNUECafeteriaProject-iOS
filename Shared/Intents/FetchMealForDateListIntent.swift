//
//  FetchMealForDateListIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation

struct FetchMealForDateListIntent: AppIntent {
    static let title: LocalizedStringResource = "특정 날짜 식단 목록 조회"
    static let description = IntentDescription("특정 날짜의 중식 또는 석식 메뉴 항목을 배열로 가져옵니다.")

    @Parameter(title: "날짜", requestValueDialog: "어느 날짜의 식단을 알려드릴까요?")
    var date: Date

    @Parameter(title: "식사 유형", requestValueDialog: "중식과 석식 중 어느 것을 알려드릴까요?")
    var mealType: MealTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$date) \(\.$mealType) 목록 조회")
    }

    func perform() async throws -> some ReturnsValue<[String]> & ProvidesDialog {
        let targetDay = Calendar.kst.startOfDay(for: date)
        guard let cached = AppGroupMealCache.load()
            .first(where: { Calendar.kst.startOfDay(for: $0.date) == targetDay })
        else {
            throw AppIntentError.noMealFound
        }
        let type = mealType.mealType
        let items: [String]
        switch type {
        case .lunch: items = cached.sortedLunchItems.map(\.name)
        case .dinner: items = cached.sortedDinnerItems.map(\.name)
        }
        let dateStr = DateFormatter.longDateLabel.string(from: cached.date)
        let menuList = items.joined(separator: ", ")
        return .result(value: items, dialog: "\(dateStr) \(type.label) 식단은 \(menuList)입니다.")
    }
}
