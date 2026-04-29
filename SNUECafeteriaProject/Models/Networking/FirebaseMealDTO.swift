//
//  FirebaseMealDTO.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

@preconcurrency import FirebaseFirestore
import Foundation

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
            lunchItems: lunch.map { MenuItem(name: $0.name) },
            dinnerItems: dinner.map { MenuItem(name: $0.name) },
            isHoliday: isHoliday,
            createdAt: createdAt.dateValue()
        )
    }
}

nonisolated struct FirestoreMenuItemDTO: Codable {
    let name: String
}

extension FirestoreMealDTO {
    static func dateToID(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")!
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    static func idToDate(_ id: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")!
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: id)
    }
}
