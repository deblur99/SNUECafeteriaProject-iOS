//
//  WatchMealStore.swift
//  SNUECafeteriaWatchApp
//

import Foundation
import KSTDateKit

@MainActor
@Observable
final class WatchMealStore {
    private(set) var meals: [CachedDayMeal] = []

    var hasCachedMeals: Bool { !meals.isEmpty }

    func reload() {
        meals = Calendar.kstMealsInWeek(from: AppGroupMealCache.load())
    }

    func meal(for date: Date) -> CachedDayMeal? {
        let targetDay = Calendar.kst.startOfDay(for: date)
        return meals.first { Calendar.kst.startOfDay(for: $0.date) == targetDay }
    }

    static func dayLabel(for date: Date) -> String {
        if Calendar.kst.isDateInToday(date) { return "오늘" }
        if Calendar.kst.isDateInTomorrow(date) { return "내일" }
        return DateFormatter.shortDateLabel.string(from: date)
    }
}
