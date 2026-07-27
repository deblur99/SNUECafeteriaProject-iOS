//
//  AppGroupMealCache.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import Foundation

/// App Groups UserDefaults에서 `[CachedDayMeal]`을 읽고 쓰는 헬퍼
/// App Group 컨테이너는 기기(iPhone / Watch)마다 별도이다.
nonisolated enum AppGroupMealCache {
    private static let lock = NSLock()
    private static nonisolated(unsafe) var cachedDefaults: UserDefaults?

    private static var defaults: UserDefaults? {
        lock.lock()
        defer { lock.unlock() }
        if cachedDefaults == nil {
            cachedDefaults = UserDefaults(suiteName: AppGroupsConfig.groupIdentifier)
        }
        return cachedDefaults
    }

    static func load() -> [CachedDayMeal] {
        guard let data = defaults?.data(forKey: AppGroupsConfig.UserDefaultsKeys.cachedMeals)
        else { return [] }
        return (try? JSONDecoder().decode([CachedDayMeal].self, from: data)) ?? []
    }

    @discardableResult
    static func save(_ meals: [CachedDayMeal]) -> Bool {
        guard !meals.isEmpty,
              let data = try? JSONEncoder().encode(meals),
              let defaults
        else { return false }
        defaults.set(data, forKey: AppGroupsConfig.UserDefaultsKeys.cachedMeals)
        defaults.set(Date(), forKey: AppGroupsConfig.UserDefaultsKeys.lastUpdated)
        return true
    }

    /// 오늘(KST) 기준으로 원격 동기화가 필요한지 판별한다.
    static func shouldRefreshToday() -> Bool {
        let meals = load()
        guard !meals.isEmpty else { return true }

        if let lastUpdated = defaults?.object(forKey: AppGroupsConfig.UserDefaultsKeys.lastUpdated) as? Date,
           Calendar.kst.isDateInToday(lastUpdated) {
            return false
        }

        guard let latestCreatedAt = meals.map(\.createdAt).max() else { return true }
        return !Calendar.kst.isDateInToday(latestCreatedAt)
    }

    /// 현재 시각 기준으로 오늘 중식 또는 석식 중 가장 가까운 식단을 반환한다.
    /// 식사 시간대가 아니거나 데이터가 없으면 nil을 반환한다.
    static func nearestMeal(from now: Date = .now) -> (meal: CachedDayMeal, type: MealType)? {
        let meals = load()
        guard let todayMeal = meals.first(where: { Calendar.kst.isDateInToday($0.date) }) else {
            return nil
        }

        guard !Calendar.kst.isDateInWeekend(now) else { return nil }

        if todayMeal.hasLunch {
            let start = Calendar.kst.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
            let end = Calendar.kst.date(bySettingHour: 13, minute: 20, second: 0, of: now)!
            if (start ... end).contains(now) { return (todayMeal, .lunch) }
        }

        if todayMeal.hasDinner {
            let start = Calendar.kst.date(bySettingHour: 13, minute: 21, second: 0, of: now)!
            let end = Calendar.kst.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
            if (start ... end).contains(now) { return (todayMeal, .dinner) }
        }

        return nil
    }

    static func resolveNearestMeal(from now: Date = .now) throws(AppIntentError) -> (meal: CachedDayMeal, type: MealType) {
        if let result = nearestMeal(from: now) {
            return result
        }

        let meals = load()
        guard let todayMeal = meals.first(where: { Calendar.kst.isDateInToday($0.date) }) else {
            throw .noMealFound
        }

        guard hasRemainingScheduleToday(todayMeal: todayMeal, now: now) else {
            throw .noRemainingMealToday
        }

        throw .noMealFound
    }

    private static func hasRemainingScheduleToday(todayMeal: CachedDayMeal, now: Date) -> Bool {
        guard !Calendar.kst.isDateInWeekend(now) else { return false }
        guard todayMeal.hasLunch || todayMeal.hasDinner else { return false }

        let lunchEnd = Calendar.kst.date(bySettingHour: 13, minute: 20, second: 0, of: now)!
        let dinnerEnd = Calendar.kst.date(bySettingHour: 18, minute: 0, second: 0, of: now)!

        if todayMeal.hasLunch, now <= lunchEnd { return true }
        if todayMeal.hasDinner, now <= dinnerEnd { return true }
        return false
    }
}

nonisolated enum AppIntentError: LocalizedError {
    case noMealFound
    case noRemainingMealToday
    case invalidDateRange
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .noMealFound: "해당 날짜의 식단 정보를 찾을 수 없습니다. 앱을 한 번 열어 데이터를 동기화해 주세요."
        case .noRemainingMealToday: "오늘은 남은 식단이 없습니다."
        case .invalidDateRange: "시작 날짜가 종료 날짜보다 늦을 수 없습니다."
        case .renderFailed: "식단 정보를 이미지로 변환하는 데 실패했습니다. 잠시 후 다시 시도해 주세요."
        }
    }
}
