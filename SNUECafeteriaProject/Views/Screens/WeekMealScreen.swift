//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct WeekMealScreen: View {
    @State private var selectedDateRange: ClosedRange<Date> = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=일, 7=토
        let sunday = cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: now))!
        let saturday = cal.date(byAdding: .day, value: 6, to: sunday)!
        return sunday ... saturday
    }()

    @State private var isSheetPresented: Bool = false
    @State private var lastSelectedDate: Date = .now

    var body: some View {
        NavigationStack {
            WeekMealListView(dateRange: selectedDateRange)
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .title) {
                        WeekSelectorView(selectedDateRange: $selectedDateRange)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("날짜 선택", systemImage: "calendar") {
                            isSheetPresented.toggle()
                        }
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    WeekDatePickerModal(
                        initialDate: lastSelectedDate
                    ) { range, date in
                        selectedDateRange = range
                        lastSelectedDate = date
                    }
                }
        }
    }
}

private struct WeekMealListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var meals: [DayMeal]

    init(dateRange: ClosedRange<Date>) {
        let start = dateRange.lowerBound
        let end = dateRange.upperBound
        _meals = Query(
            filter: #Predicate<DayMeal> { meal in
                meal.date >= start && meal.date <= end
            },
            sort: \.date
        )
    }

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
