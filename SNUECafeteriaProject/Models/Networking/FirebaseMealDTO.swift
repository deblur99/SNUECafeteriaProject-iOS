//
//  FirebaseMealDTO.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

@preconcurrency import FirebaseFirestore
import Foundation
import KSTDateKit

// @DocumentID가 Non-Sendable 및 var 사용 -> struct를 nonisolated 대신 MainActor 격리
nonisolated struct FirestoreMealDTO: Codable, Sendable {
    @DocumentID nonisolated(unsafe) var id: String? // "2026-04-27"
    let date: Timestamp // 필터링/정렬용
    let dateString: String // "2026-04-27" (디버깅)
    let lunch: [FirestoreMenuItemDTO]
    let dinner: [FirestoreMenuItemDTO]
    let isHoliday: Bool
    let createdAt: Timestamp
    let version: Int // 스키마 버전
    
    func show() {
        print("ID: \(id ?? "nil")")
        print("Date: \(date.dateValue())")
        print("Date String: \(dateString)")
        print("Lunch Items: \(lunch.map { $0.name }.joined(separator: ", "))")
        print("Dinner Items: \(dinner.map { $0.name }.joined(separator: ", "))")
        print("Is Holiday: \(isHoliday)")
        print("Created At: \(createdAt.dateValue())")
        print("Version: \(version)")
    }
    
    /// FirestoreMealDTO -> SwiftData @Model DayMeal 변환
    func toPersistenceModel() -> DayMeal {
        DayMeal(
            date: date.dateValue(),
            lunchItems: lunch.enumerated().map { MenuItem(name: $0.element.name, sortIndex: $0.offset) },
            dinnerItems: dinner.enumerated().map { MenuItem(name: $0.element.name, sortIndex: $0.offset) },
            isHoliday: isHoliday,
            createdAt: createdAt.dateValue()
        )
    }

    /// FirestoreMealDTO -> App Groups 캐시용 CachedDayMeal 변환
    func toCachedModel() -> CachedDayMeal {
        // KST 자정으로 정규화: Firestore Timestamp의 UTC 값에 관계없이 날짜 비교가 항상 일치하도록 보장
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

nonisolated struct FirestoreMenuItemDTO: Codable {
    let name: String
}
