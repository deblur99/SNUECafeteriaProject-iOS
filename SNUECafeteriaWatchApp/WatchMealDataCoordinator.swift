//
//  WatchMealDataCoordinator.swift
//  SNUECafeteriaWatchApp
//

import Foundation
import WatchConnectivityKit

/// Watch 식단 데이터 동기화 전략:
/// - iPhone 페어링·companion 가능: WatchConnectivity 우선
/// - 페어링 끊김 + 네트워크: Firestore REST로 이번 주(월~일)만 조회 후 App Group 저장
/// - 페어링 끊김 + 오프라인: App Group 로컬 캐시 사용
@MainActor
final class WatchMealDataCoordinator {
    static let shared = WatchMealDataCoordinator()

    private let network = NetworkService()
    private var isSyncing = false

    func sync(store: WatchMealStore) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        store.reload()

        // 활성화 레이스를 피하기 위해 companion 판별 전 WCSession 준비를 기다린다.
        let activated = await WatchCompanionSyncService.shared.waitUntilActivated()
        if activated, WatchCompanionAvailability.isPairedCompanionAvailable {
            await WatchCompanionSyncService.shared.requestSyncFromCompanion()
            store.reload()
            if store.hasCachedMeals {
                print("✅ companion 동기화로 식단 로드 (\(store.meals.count)일)")
                WidgetTimelineReload.requestAll()
                return
            }
            print("⚠️ companion 경로에서 식단을 받지 못함 — 네트워크 fallback 시도")
        }

        guard await network.isConnected() else {
            print("⚠️ 네트워크 없음 — 로컬 캐시만 사용 (현재 \(store.meals.count)일)")
            return
        }

        guard AppGroupMealCache.shouldRefreshToday() else { return }

        do {
            let meals = Calendar.kstMealsInWeek(
                from: try await WatchFirestoreRESTFetcher.fetchCachedMeals()
            )
            guard !meals.isEmpty else { return }
            _ = AppGroupMealCache.save(meals)
            store.reload()
            WidgetTimelineReload.requestAll()
            print("✅ Watch 독립 모드 Firestore 동기화 완료 (\(meals.count)일치)")
        } catch {
            print("⚠️ Watch Firestore 동기화 실패: \(error.localizedDescription)")
        }
    }
}
