//
//  MealDTO.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation

nonisolated struct MenuItemDTO: Codable {
    var name: String
}

nonisolated struct DayMealDTO: Codable {
    var date: Date
    var lunchItems: [MenuItemDTO]
    var dinnerItems: [MenuItemDTO]
    var isHoliday: Bool
}
