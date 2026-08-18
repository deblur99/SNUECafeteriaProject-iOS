//
//  DayMeal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import Foundation
import SwiftData
import SNUECafeteriaShared

@Model
final class DayMeal {
    @Attribute(.unique) var date: Date // 어떤 일자의 메뉴인지 식별하기 위한 필드
    @Relationship(deleteRule: .cascade, inverse: \MenuItem.lunchDayMeal) var lunchItems: [MenuItem]
    @Relationship(deleteRule: .cascade, inverse: \MenuItem.dinnerDayMeal) var dinnerItems: [MenuItem]
    var isHoliday: Bool
    var createdAt: Date // DB 조회 여부를 위한 필드
    
    /// 메뉴 아이템을 sortIndex 기준으로 정렬한 배열
    var sortedLunchItems: [MenuItem] {
        lunchItems.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    /// 메뉴 아이템을 sortIndex 기준으로 정렬한 배열
    var sortedDinnerItems: [MenuItem] {
        dinnerItems.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    /// 오늘 날짜인지 여부 (KST 기준)
    var isToday: Bool {
        Calendar.kst.isDateInToday(date)
    }
    
    /// 휴일이 아니면서 메뉴가 존재하는지 여부
    var hasLunch: Bool {
        !isHoliday && !lunchItems.isEmpty
    }
    
    /// 휴일이 아니면서 메뉴가 존재하는지 여부
    var hasDinner: Bool {
        !isHoliday && !dinnerItems.isEmpty
    }
    
    /// "4/27(월)" 형태의 날짜 레이블
    var weekdayLabel: String {
        let labels = ["일", "월", "화", "수", "목", "금", "토"]
        return labels[date.weekDayInSeoul() - 1]
    }
    
    init(
        date: Date,
        lunchItems: [MenuItem],
        dinnerItems: [MenuItem],
        isHoliday: Bool,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.lunchItems = lunchItems
        self.dinnerItems = dinnerItems
        self.isHoliday = isHoliday
        self.createdAt = createdAt
    }
    
}

extension DayMeal {
    /// DayMeal(SwiftData) → CachedDayMeal(App Groups/위젯용) 변환
    func toCachedModel() -> CachedDayMeal {
        CachedDayMeal(
            date: Calendar.kst.startOfDay(for: date),
            lunchItems: sortedLunchItems.map { CachedMenuItem(name: $0.name, sortIndex: $0.sortIndex) },
            dinnerItems: sortedDinnerItems.map { CachedMenuItem(name: $0.name, sortIndex: $0.sortIndex) },
            isHoliday: isHoliday,
            createdAt: createdAt
        )
    }
}

extension DayMeal {
    static func sample() -> [DayMeal] {
        [
            DayMeal(
                date: Date(),
                lunchItems: [
                    MenuItem(name: "바지락삼색감자수제비", sortIndex: 0),
                    MenuItem(name: "훈제오리양장피", sortIndex: 1),
                    MenuItem(name: "팽이불닭소스구이", sortIndex: 2),
                    MenuItem(name: "상추들기름통들깨무침", sortIndex: 3),
                    MenuItem(name: "사르르딸기콘", sortIndex: 4),
                    MenuItem(name: "배추김치", sortIndex: 5),
                    MenuItem(name: "깍두기", sortIndex: 6)
                ],
                dinnerItems: [
                    MenuItem(name: "가쓰오팽이국", sortIndex: 0),
                    MenuItem(name: "로제파스타", sortIndex: 1),
                    MenuItem(name: "수제마늘바게트스틱", sortIndex: 2),
                    MenuItem(name: "양상추샐러드", sortIndex: 3),
                    MenuItem(name: "깍두기", sortIndex: 4),
                    MenuItem(name: "오이피클", sortIndex: 5),
                    MenuItem(name: "배추김치", sortIndex: 6)
                ],
                isHoliday: false
            ),
            DayMeal(
                date: Calendar.kst.date(byAdding: .day, value: 1, to: Date())!,
                lunchItems: [
                    MenuItem(name: "비빔밥", sortIndex: 0),
                    MenuItem(name: "콩나물국", sortIndex: 1)
                ],
                dinnerItems: [
                    MenuItem(name: "치킨", sortIndex: 0),
                    MenuItem(name: "감자국", sortIndex: 1)
                ],
                isHoliday: false
            ),
            DayMeal(
                date: Calendar.kst.date(byAdding: .day, value: 2, to: Date())!,
                lunchItems: [
                    MenuItem(name: "우삼겹김치볶음밥", sortIndex: 0),
                    MenuItem(name: "미역국", sortIndex: 1),
                    MenuItem(name: "레몬에이드", sortIndex: 2)
                ],
                dinnerItems: [],
                isHoliday: false
            )
        ]
    }
    
    static func sampleWithOnlyLunch() -> [DayMeal] {
        [
            DayMeal(
                date: Date(),
                lunchItems: [
                    MenuItem(name: "바지락삼색감자수제비", sortIndex: 0),
                    MenuItem(name: "훈제오리양장피", sortIndex: 1),
                    MenuItem(name: "팽이불닭소스구이", sortIndex: 2),
                    MenuItem(name: "상추들기름통들깨무침", sortIndex: 3),
                    MenuItem(name: "사르르딸기콘", sortIndex: 4),
                    MenuItem(name: "배추김치", sortIndex: 5),
                    MenuItem(name: "깍두기", sortIndex: 6)
                ],
                dinnerItems: [],
                isHoliday: false
            ),
            DayMeal(
                date: Calendar.kst.date(byAdding: .day, value: 1, to: Date())!,
                lunchItems: [MenuItem(name: "비빔밥", sortIndex: 0), MenuItem(name: "콩나물국", sortIndex: 1)],
                dinnerItems: [],
                isHoliday: false
            )
        ]
    }
    
    static func sampleEmpty() -> [DayMeal] {
        [
            DayMeal(
                date: Date(),
                lunchItems: [],
                dinnerItems: [],
                isHoliday: false
            )
        ]
    }
    
    static func sampleHoliday() -> [DayMeal] {
        [
            DayMeal(
                date: Date(),
                lunchItems: [],
                dinnerItems: [],
                isHoliday: true
            )
        ]
    }
}
