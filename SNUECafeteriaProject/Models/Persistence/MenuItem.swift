//
//  MenuItem.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData

@Model
final class MenuItem {
    var name: String
    var sortIndex: Int = 0
    var lunchDayMeal: DayMeal?
    var dinnerDayMeal: DayMeal?
    
    init(name: String, sortIndex: Int = 0) {
        self.name = name
        self.sortIndex = sortIndex
    }
}
