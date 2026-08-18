//
//  FirestoreMealDTO.swift
//  SNUECafeteriaProject
//

@preconcurrency import FirebaseFirestore
import Foundation
import SNUECafeteriaShared

nonisolated struct FirestoreMealDTO: Codable, Sendable {
    let date: Timestamp
    let dateString: String
    let lunch: [FirestoreMenuItemDTO]
    let dinner: [FirestoreMenuItemDTO]
    let isHoliday: Bool
    let createdAt: Timestamp
    let version: Int

    /// FirestoreMealDTO -> App Groups 캐시용 CachedDayMeal 변환
    func toCachedModel() -> CachedDayMeal {
        let normalizedDate = Calendar.kst.startOfDay(for: date.dateValue())
        return CachedDayMeal(
            date: normalizedDate,
            lunchItems: lunch.enumerated().map { CachedMenuItem(name: $0.element.name, sortIndex: $0.offset) },
            dinnerItems: dinner.enumerated().map { CachedMenuItem(name: $0.element.name, sortIndex: $0.offset) },
            isHoliday: isHoliday,
            createdAt: createdAt.dateValue()
        )
    }
}

nonisolated struct FirestoreMenuItemDTO: Codable, Sendable {
    let name: String
}
