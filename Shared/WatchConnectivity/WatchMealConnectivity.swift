//
//  WatchMealConnectivity.swift
//  SNUECafeteriaProject
//

import Foundation
import WatchConnectivityKit

/// 이미 배포된 Watch 앱과 맞춰 둔 WatchConnectivity 키.
enum SNUEWatchSyncConfiguration {
    static let current = WatchSyncConfiguration(
        payloadKey: "cachedMeals",
        requestSyncKey: "requestMealSync",
        emptyKey: "noMeals"
    )
}

/// `AppGroupMealCache`를 WatchConnectivityKit 저장소로 연결한다.
nonisolated struct AppGroupWatchMealDataStore: WatchSyncDataStore {
    init() {}

    func loadEncodedPayload() -> Data? {
        let meals = Calendar.kstMealsInWeek(from: AppGroupMealCache.load())
        guard !meals.isEmpty else { return nil }
        return try? JSONEncoder().encode(meals)
    }

    @discardableResult
    func saveEncodedPayload(_ data: Data) -> Bool {
        guard let meals = try? JSONDecoder().decode([CachedDayMeal].self, from: data),
              !meals.isEmpty
        else { return false }
        return AppGroupMealCache.save(Calendar.kstMealsInWeek(from: meals))
    }
}

enum WatchMealConnectivityBootstrap {
    static func configure() {
        #if os(iOS)
        PhoneWatchSyncService.shared.configure(
            dataStore: AppGroupWatchMealDataStore(),
            configuration: SNUEWatchSyncConfiguration.current
        )
        scheduleRelayBridgeInstall()
        #elseif os(watchOS)
        WatchCompanionSyncService.shared.configure(
            dataStore: AppGroupWatchMealDataStore(),
            configuration: SNUEWatchSyncConfiguration.current
        )
        #endif
    }

    #if os(iOS)
    /// PhoneWatchSyncService가 delegate를 설정한 뒤 공유 릴레이 bridge를 올린다.
    private static func scheduleRelayBridgeInstall() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            MealShareRelayBridge.shared.install()
        }
    }
    #endif

    #if os(iOS)
    /// 이번 주 범위로 필터링한 뒤 Watch로 push한다.
    static func pushMeals(_ meals: [CachedDayMeal]) {
        let filtered = Calendar.kstMealsInWeek(from: meals)
        guard let data = try? JSONEncoder().encode(filtered), !data.isEmpty else { return }
        PhoneWatchSyncService.shared.pushEncodedPayload(data)
    }
    #endif
}
