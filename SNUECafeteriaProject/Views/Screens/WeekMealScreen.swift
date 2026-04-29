//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct WeekMealScreen: View {
    @Environment(MealStore.self) private var mealStore
    
    @State private var selectedDate: Date = .now
    @State private var isSheetPresented: Bool = false
    
    private var weekMeals: [DayMeal] {
        mealStore.weekMeals(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            WeekMealListView(meals: weekMeals)
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .title) {
                        WeekSelectorView(
                            selectedDate: $selectedDate,
                            availableDates: mealStore.availableDates
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("날짜 선택", systemImage: "calendar") {
                            isSheetPresented.toggle()
                        }
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    WeekDatePickerModal(
                        initialDate: selectedDate,
                        availableDates: mealStore.availableDates
                    ) { date in
                        selectedDate = date
                    }
                }
        }
    }
}

private struct WeekMealListView: View {
    let meals: [DayMeal]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        (horizontalSizeClass ?? .compact) == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        if meals.isEmpty {
            ContentUnavailableView(
                "식단 정보 없음",
                systemImage: "fork.knife",
                description: Text("해당 주의 식단 정보가 없습니다.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(meals) { meal in
                        if meal.isHoliday {
                            MealCardView(dayMeal: meal, mealType: .lunch)
                        } else {
                            if meal.hasLunch {
                                MealCardView(dayMeal: meal, mealType: .lunch)
                            }
                            if meal.hasDinner {
                                MealCardView(dayMeal: meal, mealType: .dinner)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    WeekMealScreen()
}
