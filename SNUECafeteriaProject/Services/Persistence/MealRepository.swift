//
//  MealRepository.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 6/5/26.
//

import Foundation
import SwiftData
import WidgetKit

/// 식단 데이터의 단일 진입점.
/// Firestore 동기화 → SwiftData 저장 → 앱 상태 갱신 → App Groups 동기화 → 위젯 갱신까지
/// 데이터 저장/불러오기의 전체 파이프라인을 책임진다.
@MainActor
@Observable
final class MealRepository {
    private(set) var meals: [DayMeal] = []
    private var isSyncing = false

    // MARK: - Derived Queries

    var todayMeal: DayMeal? {
        meals.first { Calendar.kst.isDateInToday($0.date) }
    }

    var tomorrowMeal: DayMeal? {
        meals.first { Calendar.kst.isDateInTomorrow($0.date) }
    }

    var availableDates: Set<Date> {
        Set(meals.map { Calendar.kst.startOfDay(for: $0.date) })
    }

    /// 현재 활성 식사 시간대에 해당하는 메뉴와 유형을 반환한다.
    /// 시간대·메뉴가 없으면 nil. 윈도우는 `MealSchedule`과 동일하다.
    var mealForNow: (meal: DayMeal, type: MealType)? {
        guard let todayMeal else { return nil }
        guard let type = MealSchedule.activeMealType() else { return nil }
        switch type {
        case .lunch where todayMeal.hasLunch: return (todayMeal, .lunch)
        case .dinner where todayMeal.hasDinner: return (todayMeal, .dinner)
        default: return nil
        }
    }

    /// 특정 날짜의 메뉴를 반환한다. 해당 날짜의 메뉴가 없으면 nil을 반환한다.
    func meal(for date: Date) -> DayMeal? {
        meals.first { Calendar.kst.isDate($0.date, inSameDayAs: date) }
    }

    /// 주어진 날짜가 속한 주(월~일)의 메뉴를 반환한다.
    func weekMeals(for date: Date) -> [DayMeal] {
        guard let interval = Calendar.kstWeekInterval(for: date) else { return [] }
        return meals.filter { meal in
            let day = Calendar.kst.startOfDay(for: meal.date)
            return day >= interval.start && day < interval.end
        }
    }

    // MARK: - Data Operations

    /// SwiftData에서 meals를 직접 로드한다. 프리뷰 및 오프라인 상황에서 사용한다.
    func load(modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<DayMeal>(sortBy: [SortDescriptor(\.date)])
        meals = try modelContext.fetch(descriptor)
    }

    /// 전체 동기화 파이프라인을 실행한다: Firestore → SwiftData → 앱 상태 갱신 → App Groups → 위젯 갱신.
    /// 이미 동기화 중이면 중복 실행을 방지한다.
    func sync(using modelContainer: ModelContainer) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let modelContext = ModelContext(modelContainer)
        await MealSyncService.syncIfNeeded(modelContext: modelContext)
        try? load(modelContext: modelContext)
        writeToAppGroups()
    }

    /// SwiftData 없이 오프라인 캐시만 불러올 때 호출한다.
    /// SwiftData 데이터가 존재하면 위젯 캐시도 함께 갱신한다.
    func loadOffline(modelContainer: ModelContainer) throws {
        let modelContext = ModelContext(modelContainer)
        try load(modelContext: modelContext)
        if !meals.isEmpty {
            writeToAppGroups()
        }
    }

    // MARK: - Private

    private func writeToAppGroups() {
        let cachedMeals = meals.map { $0.toCachedModel() }
        guard AppGroupMealCache.save(cachedMeals) else { return }
        WatchMealConnectivityBootstrap.pushMeals(cachedMeals)
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ App Groups에 식단 데이터 저장 완료 (\(cachedMeals.count)일치)")
    }
}
