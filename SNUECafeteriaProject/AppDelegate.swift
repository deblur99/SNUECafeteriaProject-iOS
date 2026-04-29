//
//  AppDelegate.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import UserNotifications

extension Notification.Name {
    static let openTodayTab = Notification.Name("openTodayTab")
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// 킬 상태에서 알림 탭으로 진입했을 때 오늘 탭 이동 대기 플래그
    var pendingOpenTodayTab = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
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
