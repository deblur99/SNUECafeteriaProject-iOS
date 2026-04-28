//
//  DataSeeder.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import Foundation
import SwiftData

enum DataSeeder {
    /// DB가 비어 있거나 아직 없는 날짜의 데이터를 삽입합니다. 날짜별로 중복 삽입을 방지합니다.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        do {
            let existing = try context.fetch(FetchDescriptor<DayMeal>())
            let existingDayKeys = Set(existing.map { seoulDayKey($0.date) })

            var inserted = false
            for meal in makeSeedData() {
                guard !existingDayKeys.contains(seoulDayKey(meal.date)) else { continue }
                context.insert(meal)
                inserted = true
            }

            if inserted {
                try context.save()
            }
        } catch {
            print("[DataSeeder] 시드 데이터 삽입 실패: \(error)")
        }
    }

    // MARK: - Helpers

    private static func seoulDayKey(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year! * 10000) + (c.month! * 100) + c.day!
    }

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal.date(from: c)!
    }

    private static func items(_ names: String...) -> [MenuItem] {
        names.map { MenuItem(name: $0) }
    }

    // MARK: - Seed Data (서울교대 학생식당 2026년 4~5월)

    private static func makeSeedData() -> [DayMeal] {
        [
            // ── 4/27 (월) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 4, 27),
                lunchItems: items("강된장찌개", "산채비빔밥", "도토리묵야채무침", "배추김치", "사르르딸기콘"),
                dinnerItems: items("맑은무채국", "해물야끼우동", "뿌링클치킨가라아게", "배추김치"),
                isHoliday: false
            ),
            // ── 4/28 (화) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 4, 28),
                lunchItems: items("백순두부탕", "대패삼겹새송이마늘구이", "오징어초무침", "올리브유참나물유자청무침", "배추김치"),
                dinnerItems: items("배추된장국", "파기름훈제볶음밥", "오븐콘치즈샐러드", "깍두기"),
                isHoliday: false
            ),
            // ── 4/29 (수) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 4, 29),
                lunchItems: items("소고기미역국", "불닭치즈닭갈비", "단호박그래놀라샐러드", "미나리무생채", "배추김치"),
                dinnerItems: items("콩나물국", "직화제육덮밥", "연유에그산도", "배추김치"),
                isHoliday: false
            ),
            // ── 4/30 (목) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 4, 30),
                lunchItems: items("가쓰오팽이국", "치즈등심돈까스", "샐러드파스타", "배추김치"),
                dinnerItems: items("유부장국", "마제덮밥", "오꼬노미야끼", "반달단무지"),
                isHoliday: false
            ),
            // ── 5/1 (금) 근로자의날 휴무 ───────────────
            DayMeal(
                date: makeDate(2026, 5, 1),
                lunchItems: [],
                dinnerItems: [],
                isHoliday: true
            ),
            // ── 5/4 (월) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 5, 4),
                lunchItems: items("*저염식국없는날* 카레라이스", "바사삭고추순살치킨", "펜네살사샐러드", "깍두기"),
                dinnerItems: items("유부장국", "통스팸김치볶음밥", "크링클컷&케찹", "콘샐러드", "깍두기"),
                isHoliday: false
            ),
            // ── 5/5 (화) 어린이날 휴무 ────────────────
            DayMeal(
                date: makeDate(2026, 5, 5),
                lunchItems: [],
                dinnerItems: [],
                isHoliday: true
            ),
            // ── 5/6 (수) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 5, 6),
                lunchItems: items("바지락삼색감자수제비", "훈제오리양장피", "팽이불닭소스구이", "상추들기름통들깨무침", "배추김치"),
                dinnerItems: items("가쓰오팽이국", "로제파스타", "수제마늘바게트스틱", "양상추샐러드", "오이피클"),
                isHoliday: false
            ),
            // ── 5/7 (목) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 5, 7),
                lunchItems: items("잔치국수", "불맛언양식불고기", "무생채", "배추김치"),
                dinnerItems: items("계란파국", "해물직화짜장밥", "꿔바로우탕수육", "레몬단무지"),
                isHoliday: false
            ),
            // ── 5/8 (금) ──────────────────────────────
            DayMeal(
                date: makeDate(2026, 5, 8),
                lunchItems: items("콩나물김치국", "삼겹오징어불고기", "비엔나소시지그린빈스볶음", "미역오이레몬무침", "깍두기"),
                dinnerItems: items("무채된장국", "차슈덮밥&볶은숙주", "계란후라이", "어묵채볶음", "배추김치"),
                isHoliday: false
            ),
        ]
    }
}
