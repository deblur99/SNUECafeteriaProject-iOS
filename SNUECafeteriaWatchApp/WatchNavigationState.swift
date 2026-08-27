//
//  WatchNavigationState.swift
//  SNUECafeteriaWatchApp
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
    /// 같은 대상으로 반복 스크롤해도 onChange가 재실행되도록 증가시킨다.
    private(set) var scrollToken: UInt = 0

    func openMeal(on date: Date, mealType: MealType?) {
        let normalizedDate = Calendar.kst.startOfDay(for: date)
        let request = WatchNavigationRequest(date: normalizedDate, mealType: mealType)
        highlightRequest = request
        pendingScrollRequest = request
        scrollToken &+= 1
    }

    func openWeeklyUpdate() {
        openMeal(on: .now, mealType: nil)
    }

    func clearPendingScroll() {
        pendingScrollRequest = nil
    }
}
