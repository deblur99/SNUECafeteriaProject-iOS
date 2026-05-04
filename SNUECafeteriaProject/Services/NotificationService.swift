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

    /// 식단이 있는 날짜에만 개별 알림 등록.
    /// 동일 식사 유형의 기존 알림이 있으면 모두 교체.
    func schedule(for type: TimeNotificationStatus.MealTimeType, at time: Date, meals: [DayMeal]) async {
        let center = UNUserNotificationCenter.current()

        // 기존 해당 유형 알림 전부 제거 (새 형식 + 구 형식 ID 모두)
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(type.notificationIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove + [type.legacyNotificationID])

        // 기기 로컬 타임존 기준 시:분 추출
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }

        // 오늘 이후 날짜 중 해당 식사 유형 데이터가 있는 날짜만 필터링
        let today = Calendar.kst.startOfDay(for: Date())
        let relevantMeals = meals.filter { meal in
            let mealDay = Calendar.kst.startOfDay(for: meal.date)
            guard mealDay >= today else { return false }
            return type == .lunch ? meal.hasLunch : meal.hasDinner
        }

        for meal in relevantMeals {
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

            // KST 기준 년·월·일 + 사용자가 설정한 시:분 조합
            var components = Calendar.kst.dateComponents([.year, .month, .day], from: meal.date)
            components.hour = hour
            components.minute = minute
            components.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = type.notificationIDPrefix + dateKey(for: meal.date)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("알림 등록 실패 (\(type.rawValue), \(meal.date)): \(error)")
            }
        }
    }

    /// 해당 식사 유형의 알림 전부 해제
    func cancel(for type: TimeNotificationStatus.MealTimeType) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(type.notificationIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove + [type.legacyNotificationID])
    }

    private func dateKey(for date: Date) -> String {
        DateFormatter.kstCompact.string(from: date)
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
    /// 개별 날짜별 알림 ID에 사용하는 접두사 (예: "notification.lunch.")
    var notificationIDPrefix: String { "notification.\(rawValue)." }
    /// 구 형식 알림 ID (마이그레이션 제거용)
    var legacyNotificationID: String { "notification.\(rawValue)" }
}
