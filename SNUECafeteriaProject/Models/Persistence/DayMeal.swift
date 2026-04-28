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
    @Attribute(.unique) var date: Date  // 어떤 일자의 메뉴인지 식별하기 위한 필드
    @Relationship(deleteRule: .cascade) var lunchItems: [MenuItem]
    @Relationship(deleteRule: .cascade) var dinnerItems: [MenuItem]
    var isHoliday: Bool
    var createdAt: Date  // DB 조회 여부를 위한 필드
    
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
        isHoliday: Bool,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.lunchItems = lunchItems
        self.dinnerItems = dinnerItems
        self.isHoliday = isHoliday
        self.createdAt = createdAt
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
