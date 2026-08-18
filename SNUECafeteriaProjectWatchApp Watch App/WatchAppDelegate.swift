//
//  WatchAppDelegate.swift
//  SNUECafeteriaProjectWatchApp Watch App
//
//  Created by 한현민 on 6/8/26.
//

import UserNotifications
import WatchKit
import WatchConnectivityKit
import SNUECafeteriaSharedWatchBridge

final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        WatchMealConnectivityBootstrap.configure()
        WatchCompanionSyncService.shared.activate()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            handleNotification(userInfo: userInfo)
            completionHandler()
        }
    }

    @MainActor
    private func handleNotification(userInfo: [AnyHashable: Any]) {
        switch NotificationPayload.destination(from: userInfo) {
        case .meal:
            let date = NotificationPayload.mealDate(from: userInfo) ?? .now
            let mealType = NotificationPayload.mealType(from: userInfo)
            WatchNavigationState.shared.openMeal(on: date, mealType: mealType)
        case .weeklyUpdate:
            WatchNavigationState.shared.openWeeklyUpdate()
        case nil:
            WatchNavigationState.shared.openMeal(on: .now, mealType: nil)
        }
    }
}
