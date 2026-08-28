//
//  AppGroupMealCache.swift
//  SNUECafeteriaProject
//

import AppGroupCodableCache
import Foundation
import KSTDateKit

/// App Groups UserDefaults에서 `[CachedDayMeal]`을 읽고 쓰는 헬퍼.
/// App Group 컨테이너는 기기(iPhone / Watch)마다 별도이다.
nonisolated enum AppGroupMealCache {
    private static let store = AppGroupCodableStore<[CachedDayMeal]>(
        suiteName: AppGroupsConfig.groupIdentifier,
        key: AppGroupsConfig.UserDefaultsKeys.cachedMeals,
        lastUpdatedKey: AppGroupsConfig.UserDefaultsKeys.lastUpdated
    )

    static func load() -> [CachedDayMeal] {
        store.load() ?? []
    }

    @discardableResult
    static func save(_ meals: [CachedDayMeal]) -> Bool {
        guard !meals.isEmpty else { return false }
        return store.save(meals)
    }

    /// 오늘(KST) 기준으로 원격 동기화가 필요한지 판별한다.
    static func shouldRefreshToday() -> Bool {
        let meals = load()
        guard !meals.isEmpty else { return true }

        if let lastUpdated = store.lastUpdated(),
           Calendar.kst.isDateInToday(lastUpdated) {
            return false
        }

        guard let latestCreatedAt = meals.map(\.createdAt).max() else { return true }
        return !Calendar.kst.isDateInToday(latestCreatedAt)
    }

    /// 특정 날짜(KST 자정 기준)의 식단을 반환한다. 없으면 `noMealFound`.
    static func meal(on date: Date) throws(AppIntentError) -> CachedDayMeal {
        let targetDay = Calendar.kst.startOfDay(for: date)
        guard let cached = load().first(where: { Calendar.kst.startOfDay(for: $0.date) == targetDay })
        else {
            throw .noMealFound
        }
        return cached
    }

    /// 현재 시각 기준으로 오늘 중식 또는 석식 중 활성 시간대의 식단을 반환한다.
    static func nearestMeal(from now: Date = .now) -> (meal: CachedDayMeal, type: MealType)? {
        guard let type = MealSchedule.activeMealType(at: now) else { return nil }
        let meals = load()
        guard let todayMeal = meals.first(where: { Calendar.kst.isDateInToday($0.date) }) else {
            return nil
        }
        switch type {
        case .lunch where todayMeal.hasLunch: return (todayMeal, .lunch)
        case .dinner where todayMeal.hasDinner: return (todayMeal, .dinner)
        default: return nil
        }
    }

    static func resolveNearestMeal(from now: Date = .now) throws(AppIntentError) -> (meal: CachedDayMeal, type: MealType) {
        if let result = nearestMeal(from: now) {
            return result
        }

        let meals = load()
        guard let todayMeal = meals.first(where: { Calendar.kst.isDateInToday($0.date) }) else {
            throw .noMealFound
        }

        guard MealSchedule.hasRemainingSchedule(
            hasLunch: todayMeal.hasLunch,
            hasDinner: todayMeal.hasDinner,
            at: now
        ) else {
            throw .noRemainingMealToday
        }

        throw .noMealFound
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
