//
//  MealSchedule.swift
//  Shared
//

import Foundation

/// 중식·석식 시간대와 “지금/가장 가까운 식사” 판별.
/// App · Widget · Watch · Intents가 동일한 윈도우를 쓰도록 한곳에 둔다.
nonisolated enum MealSchedule {
    /// 중식: 09:00–13:20 (KST)
    static let lunchEndHour = 13
    static let lunchEndMinute = 20

    /// 석식: 13:21–18:00 (KST)
    static let dinnerStartMinuteAfterLunch = 21
    static let dinnerEndHour = 18
    static let dinnerEndMinute = 0

    static let lunchStartHour = 9
    static let lunchStartMinute = 0

    /// 주어진 시각이 중식/석식 시간창 안에 있으면 해당 유형, 아니면 nil.
    static func activeMealType(at now: Date = .now) -> MealType? {
        guard !Calendar.kst.isDateInWeekend(now) else { return nil }

        let lunchStart = Calendar.kst.date(
            bySettingHour: lunchStartHour, minute: lunchStartMinute, second: 0, of: now
        )!
        let lunchEnd = Calendar.kst.date(
            bySettingHour: lunchEndHour, minute: lunchEndMinute, second: 0, of: now
        )!
        if (lunchStart ... lunchEnd).contains(now) { return .lunch }

        let dinnerStart = Calendar.kst.date(
            bySettingHour: lunchEndHour, minute: dinnerStartMinuteAfterLunch, second: 0, of: now
        )!
        let dinnerEnd = Calendar.kst.date(
            bySettingHour: dinnerEndHour, minute: dinnerEndMinute, second: 0, of: now
        )!
        if (dinnerStart ... dinnerEnd).contains(now) { return .dinner }

        return nil
    }

    /// 위젯 등에서 “표시할” 식사 유형 — 활성 창이 없으면 중식 종료 이전이면 중식, 이후면 석식.
    static func displayMealType(at now: Date = .now) -> MealType {
        if let active = activeMealType(at: now) { return active }
        let lunchEnd = Calendar.kst.date(
            bySettingHour: lunchEndHour, minute: lunchEndMinute, second: 0, of: now
        )!
        return now <= lunchEnd ? .lunch : .dinner
    }

    static func lunchEnd(of day: Date) -> Date {
        Calendar.kst.date(bySettingHour: lunchEndHour, minute: lunchEndMinute, second: 0, of: day)!
    }

    static func dinnerEnd(of day: Date) -> Date {
        Calendar.kst.date(bySettingHour: dinnerEndHour, minute: dinnerEndMinute, second: 0, of: day)!
    }

    /// 오늘 남은 식사 일정이 있는지 (주말·메뉴 없음 제외).
    static func hasRemainingSchedule(
        hasLunch: Bool,
        hasDinner: Bool,
        at now: Date = .now
    ) -> Bool {
        guard !Calendar.kst.isDateInWeekend(now) else { return false }
        guard hasLunch || hasDinner else { return false }
        if hasLunch, now <= lunchEnd(of: now) { return true }
        if hasDinner, now <= dinnerEnd(of: now) { return true }
        return false
    }

    /// 활성 창이 없을 때 스크롤/폴백용으로 쓸 다음(또는 남은) 식사 유형.
    static func fallbackMealType(
        hasLunch: Bool,
        hasDinner: Bool,
        at now: Date = .now
    ) -> MealType? {
        if hasLunch, now <= lunchEnd(of: now) { return .lunch }
        if hasDinner, now <= dinnerEnd(of: now) { return .dinner }
        if hasLunch { return .lunch }
        if hasDinner { return .dinner }
        return nil
    }
}
