//
//  MealStore.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation
import SwiftData

@Observable
final class MealStore {
    // TODO: UI에서 [DayMeal] 쿼리하던 부분 여기로 다 모으고 기존 부분은 MealStore에서 쿼리하도록 리팩토링하기
    private(set) var meals: [DayMeal] = []
    
    var todayMeal: DayMeal? {
        meals.first { Calendar.kst.isDateInToday($0.date) }
    }
    
    var tomorrowMeal: DayMeal? {
        meals.first { Calendar.kst.isDateInTomorrow($0.date) }
    }
    
    var availableDates: Set<Date> {
        Set(meals.map { Calendar.kst.startOfDay(for: $0.date) })
    }
    
    /// 주어진 날짜가 속한 주(월~일)의 메뉴를 반환한다.
    func weekMeals(for date: Date) -> [DayMeal] {
        guard let interval = Calendar.kstWeekInterval(for: date) else { return [] }
        return meals.filter { meal in
            let day = Calendar.kst.startOfDay(for: meal.date)
            return day >= interval.start && day < interval.end
        }
    }
    
    func load(modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<DayMeal>(sortBy: [SortDescriptor(\.date)])
        self.meals = try modelContext.fetch(descriptor)
    }
}
