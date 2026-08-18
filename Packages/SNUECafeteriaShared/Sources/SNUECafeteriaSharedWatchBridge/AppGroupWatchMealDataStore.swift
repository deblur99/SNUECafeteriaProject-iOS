//
//  AppGroupWatchMealDataStore.swift
//  SNUECafeteriaSharedWatchBridge
//

@_exported import SNUECafeteriaShared
import Foundation
import WatchConnectivityKit

/// 이미 배포된 Watch 앱과 맞춰 둔 WatchConnectivity 키.
public enum SNUEWatchSyncConfiguration {
    public static let current = WatchSyncConfiguration(
        payloadKey: "cachedMeals",
        requestSyncKey: "requestMealSync",
        emptyKey: "noMeals"
    )
}

/// `AppGroupMealCache`를 WatchConnectivityKit 저장소로 연결한다.
public nonisolated struct AppGroupWatchMealDataStore: WatchSyncDataStore {
    public init() {}

    public func loadEncodedPayload() -> Data? {
        let meals = Calendar.kstMealsInWeek(from: AppGroupMealCache.load())
        guard !meals.isEmpty else { return nil }
        return try? JSONEncoder().encode(meals)
    }

    @discardableResult
    public func saveEncodedPayload(_ data: Data) -> Bool {
        guard let meals = try? JSONDecoder().decode([CachedDayMeal].self, from: data),
              !meals.isEmpty
        else { return false }
        return AppGroupMealCache.save(Calendar.kstMealsInWeek(from: meals))
    }
}

public enum WatchMealConnectivityBootstrap {
    public static func configure() {
        #if os(iOS)
        PhoneWatchSyncService.shared.configure(
            dataStore: AppGroupWatchMealDataStore(),
            configuration: SNUEWatchSyncConfiguration.current
        )
        #elseif os(watchOS)
        WatchCompanionSyncService.shared.configure(
            dataStore: AppGroupWatchMealDataStore(),
            configuration: SNUEWatchSyncConfiguration.current
        )
        #endif
    }

    #if os(iOS)
    /// 이번 주 범위로 필터링한 뒤 Watch로 push한다.
    public static func pushMeals(_ meals: [CachedDayMeal]) {
        let filtered = Calendar.kstMealsInWeek(from: meals)
        guard let data = try? JSONEncoder().encode(filtered), !data.isEmpty else { return }
        PhoneWatchSyncService.shared.pushEncodedPayload(data)
    }
    #endif
}
