//
//  NotificationService.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    /// 알림 권한 요청. 이미 결정된 경우 기존 결과를 반환.
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    /// 매일 지정한 시각에 반복 알림 등록.
    /// 동일 식사 유형의 기존 알림이 있으면 교체.
    func schedule(for type: TimeNotificationStatus.MealTimeType, at time: Date) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        switch type {
        case .lunch:
            content.title = "중식 시간"
            content.body = "오늘 중식 시간입니다 🍚"
        case .dinner:
            content.title = "석식 시간"
            content.body = "오늘 석식 시간입니다 🍽️"
        }
        content.sound = .default

        // 기기 로컬 타임존 기준 시:분 추출 (UNCalendarNotificationTrigger도 로컬 타임존 사용)
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: type.notificationID,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [type.notificationID])
        center.add(request) { error in
            if let error {
                print("알림 등록 실패 (\(type.rawValue)): \(error)")
            }
        }
    }

    /// 해당 식사 유형의 알림 해제
    func cancel(for type: TimeNotificationStatus.MealTimeType) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [type.notificationID])
    }

    /// 매주 월요일 오전 9시 주간 식단 업데이트 알림 등록
    func scheduleWeekly() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "이번 주 식단 업데이트"
        content.body = "이번 주 식단이 업데이트됐어요 🗓️"
        content.sound = .default

        // 매주 월요일(weekday=2) 09:00 반복
        var components = DateComponents()
        components.weekday = 2
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.weeklyNotificationID,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyNotificationID])
        center.add(request) { error in
            if let error {
                print("주간 알림 등록 실패: \(error)")
            }
        }
    }

    /// 주간 식단 업데이트 알림 해제
    func cancelWeekly() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.weeklyNotificationID])
    }

    /// 현재 알림 권한 상태
    var authorizationStatus: UNAuthorizationStatus {
        get async {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
    }

    static let weeklyNotificationID = "notification.weekly"
}

extension TimeNotificationStatus.MealTimeType {
    var notificationID: String { "notification.\(rawValue)" }
}
