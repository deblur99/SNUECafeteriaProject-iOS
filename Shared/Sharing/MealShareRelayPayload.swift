//
//  MealShareRelayPayload.swift
//  Shared
//

import Foundation

nonisolated struct MealShareRelayPayload: Codable, Sendable {
    let date: Date
    let text: String
    let pngData: Data?
    let fileName: String

    init(date: Date, text: String, pngData: Data?, fileName: String) {
        self.date = date
        self.text = text
        self.pngData = pngData
        self.fileName = fileName
    }

    init(meal: CachedDayMeal, pngData: Data? = nil) {
        self.date = meal.date
        self.text = MealShareFormatter.text(for: meal)
        self.pngData = pngData
        self.fileName = MealShareFormatter.filename(for: meal.date, fileExtension: "png")
    }
}

enum MealShareRelayKeys {
    static let payload = "shareMealPayload"
}
