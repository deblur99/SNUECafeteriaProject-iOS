//
//  WatchMealSync.swift
//  SNUECafeteriaProject
//

import Foundation

/// iPhone ↔ Watch 식단 캐시 동기화 페이로드
nonisolated enum WatchMealSync {
    static let contextKey = "cachedMeals"
    static let requestSyncKey = "requestMealSync"
    static let noMealsKey = "noMeals"
    static let maxContextBytes = 65_536

    static func meals(from payload: [String: Any]) -> [CachedDayMeal]? {
        if payload[noMealsKey] as? Bool == true { return nil }
        guard let data = payload[contextKey] as? Data else { return nil }
        return try? JSONDecoder().decode([CachedDayMeal].self, from: data)
    }

    static func payload(for meals: [CachedDayMeal]) -> [String: Any]? {
        let filtered = Calendar.kstMealsInWeek(from: meals)
        guard !filtered.isEmpty, let data = try? JSONEncoder().encode(filtered) else { return nil }
        guard data.count <= maxContextBytes else {
            print("⚠️ Watch 전송 페이로드가 \(maxContextBytes)바이트를 초과합니다 (\(data.count)바이트)")
            return nil
        }
        return [contextKey: data]
    }

    static func emptyReply() -> [String: Any] {
        [noMealsKey: true]
    }
}
