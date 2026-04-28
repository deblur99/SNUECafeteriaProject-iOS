//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI
import SwiftData

struct TodayMealScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var todayMeals: [DayMeal]

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = Date()
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        _todayMeals = Query(filter: #Predicate<DayMeal> { meal in
            meal.date >= start && meal.date < end
        })
    }

    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let meal = todayMeals.first {
                    if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                        ContentUnavailableView(
                            meal.isHoliday ? "오늘은 휴무일입니다" : "오늘의 식단 없음",
                            systemImage: meal.isHoliday ? "moon.zzz" : "fork.knife",
                            description: Text(meal.isHoliday ? "식당 운영을 하지 않습니다." : "등록된 식단 정보가 없습니다.")
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            if meal.hasLunch {
                                MealCardView(dayMeal: meal, mealType: .lunch)
                            }
                            if meal.hasDinner {
                                MealCardView(dayMeal: meal, mealType: .dinner)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "오늘의 식단 없음",
                        systemImage: "fork.knife",
                        description: Text("등록된 식단 정보가 없습니다.")
                    )
                }
            }
            .navigationTitle("오늘의 식단")
        }
    }
}

#Preview {
    TodayMealScreen()
}
