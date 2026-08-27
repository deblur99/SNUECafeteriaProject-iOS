//
//  MacAppDelegate.swift
//  SNUECafeteriaMac
//

import AppKit
import FirebaseCore
import UserNotifications

extension Notification.Name {
    static let openTodayTab = Notification.Name("openTodayTab")
}

final class MacAppDelegate: NSObject, NSApplicationDelegate {
    var pendingOpenTodayTab = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
    }
}

extension MacAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        pendingOpenTodayTab = true
        NotificationCenter.default.post(name: .openTodayTab, object: nil)
    }
}
