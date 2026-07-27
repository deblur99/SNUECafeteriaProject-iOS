//
//  FirestoreMealDTO+iOS.swift
//  SNUECafeteriaProject
//

@preconcurrency import FirebaseFirestore
import Foundation

extension FirestoreMealDTO {
    /// FirestoreMealDTO -> SwiftData @Model DayMeal 변환
    nonisolated func toPersistenceModel() -> DayMeal {
        DayMeal(
            date: date.dateValue(),
            lunchItems: lunch.enumerated().map { MenuItem(name: $0.element.name, sortIndex: $0.offset) },
            dinnerItems: dinner.enumerated().map { MenuItem(name: $0.element.name, sortIndex: $0.offset) },
            isHoliday: isHoliday,
            createdAt: createdAt.dateValue()
        )
    }
}
