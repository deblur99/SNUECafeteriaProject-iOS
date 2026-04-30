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
    
    /// 현재 시각 또는 곧 다가올 식사 시간에 해당하는 메뉴와 식사 유형을 반환한다. 점심시간은 평일 11:20~13:20, 저녁시간은 평일 17:00~18:00로 정의한다. 해당 시간대가 아니거나 오늘 메뉴가 없는 경우 nil을 반환한다.
    var mealForNow: (meal: DayMeal, type: MealType)? {
        guard let todayMeal else { return nil }
        
        let nowDate = Date.now
        
        // 점심시간은 평일 11:20~13:20, 저녁시간은 평일 17:00~18:00
        
        // 1) 점심시간 여부 확인: 점심메뉴가 있고, 현재 시간이 평일 09:00부터 13:20인지 확인
        if todayMeal.hasLunch, !Calendar.kst.isDateInWeekend(nowDate) {
            let lunchStart = Calendar.kst.date(bySettingHour: 9, minute: 0, second: 0, of: nowDate)!
            let lunchEnd = Calendar.kst.date(bySettingHour: 13, minute: 20, second: 0, of: nowDate)!
            if nowDate >= lunchStart, nowDate <= lunchEnd {
                return (todayMeal, .lunch)
            }
        }
        
        // 2) 저녁시간 여부 확인: 저녁메뉴가 있고, 현재 시간이 평일 13:21부터 18:00인지 확인
        if todayMeal.hasDinner, !Calendar.kst.isDateInWeekend(nowDate) {
            let dinnerStart = Calendar.kst.date(bySettingHour: 13, minute: 21, second: 0, of: nowDate)!
            let dinnerEnd = Calendar.kst.date(bySettingHour: 18, minute: 0, second: 0, of: nowDate)!
            if nowDate >= dinnerStart, nowDate <= dinnerEnd {
                return (todayMeal, .dinner)
            }
        }
        
        return nil  // 조건에 맞는 메뉴가 없으면 nil 반환
    }
    
    /// 특정 날짜의 메뉴를 반환한다. 해당 날짜의 메뉴가 없으면 nil을 반환한다.
    func meal(for date: Date) -> DayMeal? {
        meals.first { Calendar.kst.isDate($0.date, inSameDayAs: date) }
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
        meals = try modelContext.fetch(descriptor)
    }
}
