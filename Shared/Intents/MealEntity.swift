//
//  MealEntity.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation

/// App Intents의 데이터 기본 단위 — 하루치 식단 정보를 담는다.
nonisolated struct MealEntity: AppEntity {
    static let defaultQuery = MealEntityQuery()
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "식단"

    /// `DateFormatter.kstDash` 형식의 날짜 문자열 (예: "2026-05-29")
    let id: String
    let date: Date
    let lunchItems: [String]
    let dinnerItems: [String]
    let isHoliday: Bool

    var displayRepresentation: DisplayRepresentation {
        let dateStr = DateFormatter.longDateLabel.string(from: date)
        let subtitle: String = isHoliday
            ? "휴일"
            : "중식 \(lunchItems.count)개, 석식 \(dinnerItems.count)개"
        return DisplayRepresentation(title: "\(dateStr) 식단", subtitle: "\(subtitle)")
    }

    init(from cached: CachedDayMeal) {
        id = DateFormatter.kstDash.string(from: cached.date)
        date = cached.date
        lunchItems = cached.sortedLunchItems.map(\.name)
        dinnerItems = cached.sortedDinnerItems.map(\.name)
        isHoliday = cached.isHoliday
    }
}
