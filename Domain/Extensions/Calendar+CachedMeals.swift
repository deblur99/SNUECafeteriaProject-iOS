//
//  Calendar+CachedMeals.swift
//  SNUECafeteriaProject
//

import Foundation
import KSTDateKit

extension Calendar {
    /// 이번 주(월~일, KST)에 해당하는 식단만 반환한다.
    nonisolated static func kstMealsInWeek(from meals: [CachedDayMeal], for date: Date = .now) -> [CachedDayMeal] {
        let visibleDays = Set(kstDatesInWeek(for: date).map { kst.startOfDay(for: $0) })
        return meals
            .filter { visibleDays.contains(kst.startOfDay(for: $0.date)) }
            .sorted { $0.date < $1.date }
    }
}
