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
    static let mainWindowID = "main"

    var pendingOpenTodayTab = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Dock 클릭 시 기존 단일 창만 앞으로 가져온다. (새 창 생성 없음)
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if let window = sender.windows.first {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
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
