//
//  MealTypeAppEnum.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import SNUECafeteriaShared

public nonisolated enum MealTypeAppEnum: String, AppEnum {
    case lunch
    case dinner

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "식사 유형"
    public static let caseDisplayRepresentations: [MealTypeAppEnum: DisplayRepresentation] = [
        .lunch: "중식",
        .dinner: "석식",
    ]

    public var mealType: MealType {
        MealType(rawValue: rawValue)!
    }
}
