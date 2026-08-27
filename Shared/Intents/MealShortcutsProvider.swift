//
//  MealShortcutsProvider.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents

struct MealShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FetchNearestMealImageIntent(),
            phrases: [
                "지금 \(.applicationName) 식단 알려줘",
                "\(.applicationName) 지금 뭐 먹어",
                "가장 가까운 \(.applicationName) 식단",
            ],
            shortTitle: "지금 식단",
            systemImageName: "fork.knife.circle"
        )
        AppShortcut(
            intent: FetchNearestMealTextIntent(),
            phrases: [
                "지금 \(.applicationName) 식단 텍스트",
                "\(.applicationName) 지금 식단 텍스트",
            ],
            shortTitle: "지금 식단 텍스트",
            systemImageName: "doc.text"
        )
        AppShortcut(
            intent: FetchNearestMealListIntent(),
            phrases: [
                "지금 \(.applicationName) 식단 목록",
                "\(.applicationName) 지금 식단 메뉴 목록",
            ],
            shortTitle: "지금 식단 목록",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: FetchMealForDateImageIntent(),
            phrases: [
                "\(.applicationName) 날짜 식단 알려줘",
                "날짜별 \(.applicationName) 식단",
            ],
            shortTitle: "날짜 식단",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: FetchMealForDateTextIntent(),
            phrases: [
                "\(.applicationName) 날짜 식단 텍스트",
                "날짜별 \(.applicationName) 식단 텍스트",
            ],
            shortTitle: "날짜 식단 텍스트",
            systemImageName: "doc.text"
        )
        AppShortcut(
            intent: FetchMealForDateListIntent(),
            phrases: [
                "\(.applicationName) 날짜 식단 목록",
                "날짜별 \(.applicationName) 식단 메뉴 목록",
            ],
            shortTitle: "날짜 식단 목록",
            systemImageName: "list.bullet.rectangle"
        )
        AppShortcut(
            intent: FetchMealsForPeriodIntent(),
            phrases: [
                "\(.applicationName) 기간 식단",
                "\(.applicationName) 주간 식단 알려줘",
            ],
            shortTitle: "기간 식단",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: OpenAppIntent(),
            phrases: [
                "\(.applicationName) 앱 열어",
                "\(.applicationName) 열기",
            ],
            shortTitle: "앱 열기",
            systemImageName: "fork.knife"
        )
    }
}

