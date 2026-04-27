//
//  Date+Seoul.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation

extension Date {
    /// 서울 기준으로 요일을 반환합니다. (1: 일요일, 2: 월요일, ..., 7: 토요일)
    func weekDayInSeoul() -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .init(identifier: "Asia/Seoul")!
        return calendar.component(.weekday, from: self)
    }
}
