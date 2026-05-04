//
//  DateFormatter+App.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/4/26.
//

import Foundation

extension DateFormatter {
    /// "yyyy-MM-dd" (KST) — Firestore 문서 ID 및 날짜 문자열 변환 형식
    nonisolated static let kstDash: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Seoul")!
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// "yyyyMMdd" (KST) — 알림 식별자 접미사 형식
    nonisolated static let kstCompact: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Seoul")!
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    /// "M/d (E)" (ko_KR) — 날짜 짧은 레이블 (예: "5/4 (월)")
    nonisolated static let shortDateLabel: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d (E)"
        return f
    }()

    /// "M월 d일" (ko_KR) — 주간 범위 표시 (예: "5월 4일")
    nonisolated static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f
    }()

    /// "HH:mm" — 알림 시간 표시 (예: "11:30")
    nonisolated static let hourMinute: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}
