//
//  MealShareImageFactory.swift
//  SNUECafeteriaProject
//

import SwiftUI

enum MealShareImageFactory {
    @MainActor
    static func makeShareableImage(for meal: DayMeal, mealRepository: MealRepository) -> ShareableImage? {
        guard !meal.isHoliday else { return nil }
        let renderer = ImageRenderer(
            content: MealShareContent(dayMeal: meal).environment(mealRepository)
        )
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return nil }
        return ShareableImage(
            uiImage: uiImage,
            shareDate: meal.date,
            shareText: MealShareFormatter.text(for: meal.toCachedModel())
        )
    }
}
