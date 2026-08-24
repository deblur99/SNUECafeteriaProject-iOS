//
//  WatchMealDaySectionView.swift
//  SNUECafeteriaWatchApp
//

import SwiftUI

struct WatchMealDaySectionView: View {
    let date: Date
    let meal: CachedDayMeal?
    let highlightedMealType: MealType?

    private var isHoliday: Bool { meal?.isHoliday ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(WatchMealStore.dayLabel(for: date))
                .font(.headline)

            if let meal {
                WatchMealCardView(
                    mealType: .lunch,
                    items: meal.sortedLunchItems,
                    isHoliday: isHoliday,
                    isHighlighted: highlightedMealType == .lunch
                )
                WatchMealCardView(
                    mealType: .dinner,
                    items: meal.sortedDinnerItems,
                    isHoliday: isHoliday,
                    isHighlighted: highlightedMealType == .dinner
                )
            } else {
                Text("식단 없음")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
    }
}
