//
//  DayMeal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class DayMeal {
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
        return labels[date.weekDayInSeoul() - 1]
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
