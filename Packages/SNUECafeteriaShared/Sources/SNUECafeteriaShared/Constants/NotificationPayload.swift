//
//  NotificationPayload.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 6/8/26.
//

import Foundation

public nonisolated enum NotificationPayload {
    public enum Key {
        public static let destination = "destination"
        public static let mealDate = "mealDate"
        public static let mealType = "mealType"
    }

    public enum Destination: String {
        case meal
        case weeklyUpdate
    }

    public static func mealInfo(date: Date, mealType: MealType) -> [String: String] {
        [
            Key.destination: Destination.meal.rawValue,
            Key.mealDate: DateFormatter.kstDash.string(from: date),
            Key.mealType: mealType.rawValue,
        ]
    }

    public static func weeklyUpdateInfo() -> [String: String] {
        [Key.destination: Destination.weeklyUpdate.rawValue]
    }

    public static func destination(from userInfo: [AnyHashable: Any]) -> Destination? {
        guard let raw = userInfo[Key.destination] as? String else { return nil }
        return Destination(rawValue: raw)
    }

    public static func mealDate(from userInfo: [AnyHashable: Any]) -> Date? {
        guard let raw = userInfo[Key.mealDate] as? String else { return nil }
        return DateFormatter.kstDash.date(from: raw)
    }

    public static func mealType(from userInfo: [AnyHashable: Any]) -> MealType? {
        guard let raw = userInfo[Key.mealType] as? String else { return nil }
        return MealType(rawValue: raw)
    }
}
