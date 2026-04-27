//
//  Meal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

nonisolated enum MealType: Codable {
    case lunch, dinner
}

// Codable 구현 시 Decode, Encode 모두 구현 (각각 생성자, 메서드)
@Model
class MenuItem {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

// SwiftData에 Codable 설정 시 별도 구현 필요
@Model
class DayMeal {
    var date: Date
    var lunchItems: [MenuItem]
    var dinnerItems: [MenuItem]
    var isHoliday: Bool
    
    var hasLunch: Bool {
        !isHoliday && !lunchItems.isEmpty
    }
    
    var hasDinner: Bool {
        !isHoliday && !dinnerItems.isEmpty
    }
    
    var weekdayLabel: String {
        let labels = ["일", "월", "화", "수", "목", "금", "토"]
        return labels[Date().weekDayInSeoul() - 1]
    }
    
    init(
        date: Date,
        lunchItems: [MenuItem],
        dinnerItems: [MenuItem],
        isHoliday: Bool
    ) {
        self.date = date
        self.lunchItems = lunchItems
        self.dinnerItems = dinnerItems
        self.isHoliday = isHoliday
    }

    static func sample() -> DayMeal {
        DayMeal(
            date: Date(),
            lunchItems: [MenuItem(name: "김치볶음밥"), MenuItem(name: "된장국")],
            dinnerItems: [MenuItem(name: "불고기"), MenuItem(name: "미역국")],
            isHoliday: false
        )
    }
}

@Model
class WeekMeal {
    /// [weekStart] must be a Monday.
    var weekStart: Date
    /// Mon–Fri in order (5 entries).
    var days: [DayMeal]
    
    init(weekStart: Date, days: [DayMeal]) {
        self.weekStart = weekStart
        self.days = days
    }
}

@Model
class MealCacheData {
    var thisWeek: WeekMeal
    var nextWeek: WeekMeal
    var savedAt: Date
    
    init(thisWeek: WeekMeal, nextWeek: WeekMeal, savedAt: Date) {
        self.thisWeek = thisWeek
        self.nextWeek = nextWeek
        self.savedAt = savedAt
    }
    
    var isStale: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let isSameYear = calendar.component(.year, from: savedAt) != calendar.component(.year, from: now)
        let isSameMonth = calendar.component(.month, from: savedAt) != calendar.component(.month, from: now)
        let isSameDay = calendar.component(.day, from: savedAt) != calendar.component(.day, from: now)
        
        return isSameYear || isSameMonth || isSameDay
    }
}

extension Date {
    /// 서울 기준으로 요일을 반환합니다. (1: 일요일, 2: 월요일, ..., 7: 토요일)
    func weekDayInSeoul() -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .init(identifier: "Asia/Seoul")!
        return calendar.component(.weekday, from: self)
    }
}
