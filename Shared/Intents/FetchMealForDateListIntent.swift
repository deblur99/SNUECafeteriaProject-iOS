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
    static let description = IntentDescription("특정 날짜의 중식 또는 석식 메뉴를 앱 공유와 동일한 텍스트 형식으로 가져옵니다.")

    @Parameter(title: "날짜", requestValueDialog: "어느 날짜의 식단을 알려드릴까요?")
    var date: Date

    @Parameter(title: "식사 유형", requestValueDialog: "중식과 석식 중 어느 것을 알려드릴까요?")
    var mealType: MealTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$date) \(\.$mealType) 목록 조회")
    }

    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let cached = try AppGroupMealCache.meal(on: date)
        let type = mealType.mealType
        let text = MealShareFormatter.text(for: cached, mealType: type)
        let dateStr = DateFormatter.longDateLabel.string(from: cached.date)
        return .result(value: text, dialog: "\(dateStr) \(type.label) 식단을 가져왔습니다.")
    }
}
