//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct TodayMealScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(MealStore.self) private var mealStore

    private var todayMeal: DayMeal? {
        mealStore.todayMeal
    }

    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            VStack {
                if let meal = todayMeal {
                    if meal.isHoliday || (!meal.hasLunch && !meal.hasDinner) {
                        ContentUnavailableView(
                            meal.isHoliday ? "오늘은 휴무일입니다" : "오늘의 식단 없음",
                            systemImage: meal.isHoliday ? "moon.zzz" : "fork.knife",
                            description: Text(meal.isHoliday ? "식당 운영을 하지 않습니다." : "등록된 식단 정보가 없습니다.")
                        )
                    } else {
                        ScrollView {
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
                    }
                } else {
                    ContentUnavailableView(
                        "오늘의 식단 없음",
                        systemImage: "fork.knife",
                        description: Text("등록된 식단 정보가 없습니다.")
                    )
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("오늘의 식단")
        }
    }
}

#Preview("Sample Data") {
    TodayMealScreen()
        .modelContainer(DayMealPreviewHelper.previewContainer(type: .normal))
}

#Preview("No Data") {
    TodayMealScreen()
        .modelContainer(DayMealPreviewHelper.previewContainer(type: .empty))
}

#Preview("Holiday Data") {
    TodayMealScreen()
        .modelContainer(DayMealPreviewHelper.previewContainer(type: .holiday))
}
