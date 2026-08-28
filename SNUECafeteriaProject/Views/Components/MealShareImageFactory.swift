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
        guard let cgImage = renderer.cgImage,
              let pngData = CGImagePNGEncoder.pngData(from: cgImage)
        else { return nil }
        return ShareableImage(
            pngData: pngData,
            shareDate: meal.date,
            shareText: MealShareFormatter
                .text(for: meal.toCachedModel())
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
