//
//  Calendar+KST.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import Foundation

extension Calendar {
    /// 서울 타임존, 월요일 시작 달력
    static let kst: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        cal.firstWeekday = 2 // 월요일
        return cal
    }()

    /// 주어진 날짜가 속한 주(월~일)의 DateInterval을 반환한다.
    static func kstWeekInterval(for date: Date) -> DateInterval? {
        kst.dateInterval(of: .weekOfYear, for: date)
    }
}
