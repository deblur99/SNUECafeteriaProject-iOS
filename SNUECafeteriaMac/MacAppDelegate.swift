//
//  MacAppDelegate.swift
//  SNUECafeteriaMac
//

import AppKit
import FirebaseCore
import UserNotifications

extension Notification.Name {
    static let openTodayTab = Notification.Name("openTodayTab")
    static let openDeepLinkURL = Notification.Name("openDeepLinkURL")
}

final class MacAppDelegate: NSObject, NSApplicationDelegate {
    static let mainWindowID = "main"
    static let deepLinkHosts = ["today", "tomorrow"]

    var pendingOpenTodayTab = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
    }

    /// 위젯 등으로 URL이 열릴 때 기존 창만 앞으로 가져온다.
    func application(_ application: NSApplication, open urls: [URL]) {
        focusMainWindow(in: application)
        closeDuplicateMainWindows(in: application)
        for url in urls where url.scheme == "snuecafeteria" {
            NotificationCenter.default.post(name: .openDeepLinkURL, object: url)
        }
    }

    /// Dock 클릭 시 기존 단일 창만 앞으로 가져온다. (새 창 생성 없음)
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        focusMainWindow(in: sender)
        closeDuplicateMainWindows(in: sender)
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        closeDuplicateMainWindows(in: NSApp)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func focusMainWindow(in application: NSApplication) {
        guard let window = mainWindows(in: application).first else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        application.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// 위젯 URL이 Scene을 하나 더 띄운 경우 첫 창만 남긴다.
    private func closeDuplicateMainWindows(in application: NSApplication) {
        let windows = mainWindows(in: application)
        guard windows.count > 1 else { return }
        for window in windows.dropFirst() {
            window.close()
        }
    }

    private func mainWindows(in application: NSApplication) -> [NSWindow] {
        application.windows.filter { window in
            guard window.canBecomeMain else { return false }
            guard !(window is NSPanel) else { return false }
            // 상태바·팝오버 등 유틸 창 제외
            return window.styleMask.contains(.titled)
        }
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
