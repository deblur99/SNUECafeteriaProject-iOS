//
//  AppDelegate.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import AppIntents
import FirebaseCore
import FirebaseFirestore
import UIKit
import UserNotifications
import WidgetKit

extension Notification.Name {
    static let openTodayTab = Notification.Name("openTodayTab")
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// 킬 상태에서 알림 탭으로 진입했을 때 오늘 탭 이동 대기 플래그
    var pendingOpenTodayTab = false
    // App Group 관련
    private var mealListenerRegistration: ListenerRegistration?
    private let appGroupsDefaults = UserDefaults(
        suiteName: AppGroupsConfig.groupIdentifier
    )!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self

        // Background 실행(App Intents 트리거 등)에서는 기존 캐시를 보존하기 위해 리스너 설정 건너뜀
        if application.applicationState != .background {
            setupMealListener()
        }
        MealShortcutsProvider.updateAppShortcutParameters()

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Background → Foreground 전환 시 리스너 재설정하여 캐시 최신화
        setupMealListener()
    }

    private func setupMealListener() {
        mealListenerRegistration?.remove()

        let db = Firestore.firestore()

        // 오늘부터 7일치 메뉴를 실시간으로 감시
        let today = Calendar.kst.startOfDay(for: Date())
        let weekLater = Calendar.kst.date(byAdding: .day, value: 7, to: today)!

        // 범위를 오늘자부터 7일치까지 제한하기
        mealListenerRegistration = db.collection("meals")
            .whereField("date", isGreaterThanOrEqualTo: today)
            .whereField("date", isLessThan: weekLater)
            .addSnapshotListener { snapshot, error in
                guard error == nil else {
                    print("Firestore 실시간 감시 오류: \(error!)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("Firestore 실시간 감시: 문서 없음")
                    return
                }

                // 첫 번째 문서의 구조 확인
                if let firstDoc = documents.first {
                    print("📄 Firestore 문서 구조:")
                    print(firstDoc.data())
                }

                do {
                    // 문서 -> FirestoreMealDTO -> CachedDayMeal -> JSON 변환 후 App Group에 저장
                    let meals = documents.compactMap { doc -> CachedDayMeal? in
                        do {
                            let dto = try doc.data(as: FirestoreMealDTO.self)
                            let meal = dto.toCachedModel()
                            print("✅ \(DateFormatter.longDateLabel.string(from: meal.date)): 중식 \(meal.lunchItems.count)개, 석식 \(meal.dinnerItems.count)개")
                            return meal
                        } catch {
                            print("❌ 디코딩 실패: \(doc.documentID) - \(error)")
                            return nil
                        }
                    }

                    // Firestore 로컬 캐시 미스 등으로 빈 응답이 오면 기존 캐시를 덮어쓰지 않음
                    guard !meals.isEmpty else {
                        print("⚠️ Firestore 빈 데이터 — 기존 App Groups 캐시 유지")
                        return
                    }

                    let mealsData = try JSONEncoder().encode(meals)
                    self.appGroupsDefaults.set(mealsData, forKey: AppGroupsConfig.UserDefaultsKeys.cachedMeals)
                    // 위젯 익스텐션은 별도 프로세스 — 리로드 전에 디스크 flush를 강제해야 위젯이 최신 데이터를 읽음
                    self.appGroupsDefaults.synchronize()
                    print("✅ App Groups 캐시 업데이트: \(meals.count)개 메뉴")
                    // 0.3초 딜레이: 실기기 파일 쓰기 완전 완료 후 위젯이 UserDefaults를 읽도록 보장
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        print("🔄 위젯 타임라인 갱신 요청")
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } catch {
                    print("❌ JSON 인코딩 실패: \(error)")
                }
            }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 포그라운드에서 알림이 도착할 때 배너와 사운드 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// 알림을 탭했을 때 오늘 탭으로 이동
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pendingOpenTodayTab = true
        NotificationCenter.default.post(name: .openTodayTab, object: nil)
        completionHandler()
    }
}
