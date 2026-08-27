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
        guard let cgImage = renderer.cgImage else { return nil }
        let uiImage = UIImage(cgImage: cgImage, scale: renderer.scale, orientation: .up)
        return ShareableImage(
            uiImage: uiImage,
            shareDate: meal.date,
            shareText: MealShareFormatter.text(for: meal.toCachedModel())
        )
    }
}
