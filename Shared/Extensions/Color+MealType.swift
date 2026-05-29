//
//  Color+MealType.swift
//  Shared
//
//  Created by 한현민 on 5/18/26.
//

import SwiftUI

extension Color {
    static func mealColor(for mealType: MealType) -> Color {
        switch mealType {
        case .lunch: return .orange
        case .dinner: return .indigo
        }
    }
}

