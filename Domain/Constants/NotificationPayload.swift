//
//  NotificationPayload.swift
//  SNUECafeteriaProject
//

import Foundation
import KSTDateKit

nonisolated enum NotificationPayload {
    enum Key {
        static let destination = "destination"
        static let mealDate = "mealDate"
        static let mealType = "mealType"
    }

    enum Destination: String {
        case meal
        case weeklyUpdate
    }

    static func mealInfo(date: Date, mealType: MealType) -> [String: String] {
        [
            Key.destination: Destination.meal.rawValue,
            Key.mealDate: DateFormatter.kstDash.string(from: date),
            Key.mealType: mealType.rawValue,
        ]
    }

    static func weeklyUpdateInfo() -> [String: String] {
        [Key.destination: Destination.weeklyUpdate.rawValue]
    }

    static func destination(from userInfo: [AnyHashable: Any]) -> Destination? {
        guard let raw = userInfo[Key.destination] as? String else { return nil }
        return Destination(rawValue: raw)
    }

    static func mealDate(from userInfo: [AnyHashable: Any]) -> Date? {
        guard let raw = userInfo[Key.mealDate] as? String else { return nil }
        return DateFormatter.kstDash.date(from: raw)
    }

    static func mealType(from userInfo: [AnyHashable: Any]) -> MealType? {
        guard let raw = userInfo[Key.mealType] as? String else { return nil }
        return MealType(rawValue: raw)
    }
}
