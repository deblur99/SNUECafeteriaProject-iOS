//
//  MealType.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

public nonisolated enum MealType: String, Codable, CaseIterable, Sendable {
    case lunch
    case dinner

    public var label: String { self == .lunch ? "중식" : "석식" }
    
    public var color: Color { self == .lunch ? .orange : .indigo }
}
