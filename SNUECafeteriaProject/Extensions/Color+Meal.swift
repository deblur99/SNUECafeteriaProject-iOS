//
//  Color+Meal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/30/26.
//

import SwiftUI

extension Color {
    static func mealColor(for mealType: MealType) -> Color {
        switch mealType {
        case .lunch:
            return .lunch
        case .dinner:
            return .dinner
        }
    }
}
