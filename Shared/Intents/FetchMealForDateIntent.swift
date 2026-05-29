//
//  FetchMealForDateIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation
import SwiftUI

struct FetchMealForDateIntent: AppIntent {
    static let title: LocalizedStringResource = "특정 날짜 식단 조회"
    static let description = IntentDescription("특정 날짜의 식단 메뉴를 가져옵니다.")

    @Parameter(title: "날짜", requestValueDialog: "어느 날짜의 식단을 알려드릴까요?")
    var date: Date

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$date) 식단 조회")
    }

    func perform() async throws -> some ReturnsValue<MealEntity> & ProvidesDialog & ShowsSnippetView {
        let targetDay = Calendar.kst.startOfDay(for: date)
        guard let cached = AppGroupMealCache.load()
            .first(where: { Calendar.kst.startOfDay(for: $0.date) == targetDay })
        else {
            throw AppIntentError.noMealFound
        }
        let entity = MealEntity(from: cached)
        let dateStr = DateFormatter.longDateLabel.string(from: entity.date)
        return .result(value: entity, dialog: "\(dateStr) 식단을 가져왔습니다.") {
            DayMealSnippetView(entity: entity)
        }
    }
}
