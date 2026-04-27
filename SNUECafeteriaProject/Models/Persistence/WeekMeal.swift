//
//  WeekMeal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class WeekMeal {
    /// [weekStart] must be a Monday.
    var weekStart: Date
    /// Mon–Fri in order (5 entries).
    var days: [DayMeal]
    
    init(weekStart: Date, days: [DayMeal]) {
        self.weekStart = weekStart
        self.days = days
    }
}
