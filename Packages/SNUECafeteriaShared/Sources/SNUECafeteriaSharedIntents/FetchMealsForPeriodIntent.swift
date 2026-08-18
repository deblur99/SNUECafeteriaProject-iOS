//
//  FetchMealsForPeriodIntent.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation
import SNUECafeteriaShared

public struct FetchMealsForPeriodIntent: AppIntent {
    public init() {}

    public static let title: LocalizedStringResource = "기간별 식단 조회"
    public static let description = IntentDescription("특정 기간 내 날짜별 식단 메뉴를 가져옵니다.")

    @Parameter(title: "시작 날짜", requestValueDialog: "시작 날짜를 알려주세요.")
    public var startDate: Date

    @Parameter(title: "종료 날짜", requestValueDialog: "종료 날짜를 알려주세요.")
    public var endDate: Date

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$startDate)부터 \(\.$endDate)까지 식단 조회")
    }

    public func perform() async throws -> some ReturnsValue<[MealEntity]> & ProvidesDialog {
        let start = Calendar.kst.startOfDay(for: startDate)
        let end = Calendar.kst.startOfDay(for: endDate)
        guard start <= end else { throw MealIntentError.invalidDateRange }

        let entities = AppGroupMealCache.load()
            .filter {
                let day = Calendar.kst.startOfDay(for: $0.date)
                return day >= start && day <= end
            }
            .sorted { $0.date < $1.date }
            .map(MealEntity.init)

        guard !entities.isEmpty else { throw MealIntentError.noMealFound }

        let startStr = DateFormatter.longDateLabel.string(from: start)
        let endStr = DateFormatter.longDateLabel.string(from: end)
        return .result(value: entities, dialog: "\(startStr)부터 \(endStr)까지 \(entities.count)일치 식단을 가져왔습니다.")
    }
}
