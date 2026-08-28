//
//  CachedMealModels.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/19/26.
//

import Foundation
import KSTDateKit

nonisolated struct CachedMenuItem: Codable {
    let name: String
    let sortIndex: Int
}

nonisolated struct CachedDayMeal: Codable {
    let date: Date
    let lunchItems: [CachedMenuItem]
    let dinnerItems: [CachedMenuItem]
    let isHoliday: Bool
    let createdAt: Date

    var hasLunch: Bool { !isHoliday && !lunchItems.isEmpty }
    var hasDinner: Bool { !isHoliday && !dinnerItems.isEmpty }

    var sortedLunchItems: [CachedMenuItem] {
        lunchItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    var sortedDinnerItems: [CachedMenuItem] {
        dinnerItems.sorted { $0.sortIndex < $1.sortIndex }
    }
}

extension CachedDayMeal {
    nonisolated static func sample() -> [CachedDayMeal] {
        let today = Calendar.kst.startOfDay(for: Date())
        let tomorrow = Calendar.kst.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = Calendar.kst.date(byAdding: .day, value: 2, to: today)!
        return [
            CachedDayMeal(
                date: today,
                lunchItems: [
                    CachedMenuItem(name: "바지락삼색감자수제비", sortIndex: 0),
                    CachedMenuItem(name: "훈제오리양장피", sortIndex: 1),
                    CachedMenuItem(name: "팽이불닭소스구이", sortIndex: 2),
                    CachedMenuItem(name: "상추들기름통들깨무침", sortIndex: 3),
                    CachedMenuItem(name: "사르르딸기콘", sortIndex: 4),
                    CachedMenuItem(name: "배추김치", sortIndex: 5),
                    CachedMenuItem(name: "깍두기", sortIndex: 6),
                ],
                dinnerItems: [
                    CachedMenuItem(name: "가쓰오팽이국", sortIndex: 0),
                    CachedMenuItem(name: "로제파스타", sortIndex: 1),
                    CachedMenuItem(name: "수제마늘바게트스틱", sortIndex: 2),
                    CachedMenuItem(name: "양상추샐러드", sortIndex: 3),
                    CachedMenuItem(name: "깍두기", sortIndex: 4),
                    CachedMenuItem(name: "오이피클", sortIndex: 5),
                    CachedMenuItem(name: "배추김치", sortIndex: 6),
                ],
                isHoliday: false,
                createdAt: Date()
            ),
            CachedDayMeal(
                date: tomorrow,
                lunchItems: [
                    CachedMenuItem(name: "비빔밥", sortIndex: 0),
                    CachedMenuItem(name: "콩나물국", sortIndex: 1),
                ],
                dinnerItems: [
                    CachedMenuItem(name: "치킨", sortIndex: 0),
                    CachedMenuItem(name: "감자국", sortIndex: 1),
                ],
                isHoliday: false,
                createdAt: Date()
            ),
            CachedDayMeal(
                date: dayAfter,
                lunchItems: [
                    CachedMenuItem(name: "우삼겹김치볶음밥", sortIndex: 0),
                    CachedMenuItem(name: "미역국", sortIndex: 1),
                    CachedMenuItem(name: "레몬에이드", sortIndex: 2),
                ],
                dinnerItems: [],
                isHoliday: false,
                createdAt: Date()
            ),
        ]
    }
}
