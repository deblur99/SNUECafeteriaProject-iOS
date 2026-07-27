//
//  WatchNavigationState.swift
//  SNUECafeteriaProjectWatchApp Watch App
//
//  Created by 한현민 on 6/8/26.
//

import Foundation

struct WatchNavigationRequest: Equatable {
    let date: Date
    let mealType: MealType?
}

@MainActor
@Observable
final class WatchNavigationState {
    static let shared = WatchNavigationState()

    private(set) var pendingScrollRequest: WatchNavigationRequest?
    private(set) var highlightRequest: WatchNavigationRequest?

    func openMeal(on date: Date, mealType: MealType?) {
        let normalizedDate = Calendar.kst.startOfDay(for: date)
        let request = WatchNavigationRequest(date: normalizedDate, mealType: mealType)
        pendingScrollRequest = request
        highlightRequest = request
    }

    func openWeeklyUpdate() {
        openMeal(on: .now, mealType: nil)
    }

    func clearPendingScroll() {
        pendingScrollRequest = nil
    }
}
