//
//  MealCacheData.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class MealCacheData {
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
        
        let isSameYear = calendar.component(.year, from: savedAt) == calendar.component(.year, from: now)
        let isSameMonth = calendar.component(.month, from: savedAt) == calendar.component(.month, from: now)
        let isSameDay = calendar.component(.day, from: savedAt) == calendar.component(.day, from: now)
        
        return !(isSameYear && isSameMonth && isSameDay)
    }
}
