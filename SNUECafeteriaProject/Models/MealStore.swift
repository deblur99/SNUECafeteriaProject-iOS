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
        meals.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var tomorrowMeal: DayMeal? {
        meals.first { Calendar.current.isDateInTomorrow($0.date) }
    }
    
    var availableDates: Set<Date> {
        Set(meals.map { Calendar.current.startOfDay(for: $0.date) })
    }
    
    /// 주간 메뉴를 가져오는 메서드
    func meals(for weekStartDate: Date) -> [DayMeal] {
        // TODO: 특정 날짜를 매개변수로 넘기면 어떻게 그 날짜가 속한 주의 메뉴들을 가져올 수 있는지 알아보기
        []
    }
    
    func load(modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<DayMeal>(sortBy: [SortDescriptor(\.date)])
        self.meals = try modelContext.fetch(descriptor)
    }
}
