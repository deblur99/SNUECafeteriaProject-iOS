//
//  MealType.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

nonisolated enum MealType: String, Codable, CaseIterable {
    case lunch
    case dinner

    var label: String { self == .lunch ? "중식" : "석식" }

    var color: Color { .mealColor(for: self) }
}
