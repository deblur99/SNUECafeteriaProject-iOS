//
//  Calendar+KST.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation

extension Calendar {
    /// 서울 타임존, 월요일 시작 달력
    public nonisolated static let kst: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        cal.firstWeekday = 2 // 월요일
        return cal
    }()

    /// 주어진 날짜가 속한 주(월~일)의 DateInterval을 반환한다.
    public nonisolated static func kstWeekInterval(for date: Date) -> DateInterval? {
        kst.dateInterval(of: .weekOfYear, for: date)
    }

    /// 주어진 날짜가 속한 이번 주(월~일, KST)의 날짜 목록을 반환한다.
    public nonisolated static func kstDatesInWeek(for date: Date = .now) -> [Date] {
        guard let interval = kstWeekInterval(for: date) else {
            return [kst.startOfDay(for: date)]
        }

        var dates: [Date] = []
        var current = kst.startOfDay(for: interval.start)
        while current < interval.end {
            dates.append(current)
            guard let next = kst.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    /// 이번 주(월~일, KST)에 해당하는 식단만 반환한다.
    public nonisolated static func kstMealsInWeek(from meals: [CachedDayMeal], for date: Date = .now) -> [CachedDayMeal] {
        let visibleDays = Set(kstDatesInWeek(for: date).map { kst.startOfDay(for: $0) })
        return meals
            .filter { visibleDays.contains(kst.startOfDay(for: $0.date)) }
            .sorted { $0.date < $1.date }
    }
}
