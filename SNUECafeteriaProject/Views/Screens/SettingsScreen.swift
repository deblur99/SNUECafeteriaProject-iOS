//
//  SettingsScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

nonisolated struct TimeNotificationStatus: Codable, Equatable {
    let mealTimeType: MealTimeType
    var notificationTime: Date?
    var isEnabled: Bool
    
    nonisolated enum MealTimeType: String, Codable {
        case lunch, dinner
    }
    
    /// `매일 hh:mm에 알림` 형태로 반환
    var description: String {
        guard let notificationTime = notificationTime else {
            return "알림 시간 미설정"
        }
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: notificationTime)
        
        return "매일 \(timeString)에 알림"
    }
    
    static var lunchDefault: TimeNotificationStatus {
        // GMT+9 기준 오늘자 오전 11시 반
        let lunchTime = Calendar.current.date(
            bySettingHour: 11,
            minute: 30,
            second: 0,
            of: Date()
        )!
        
        return .init(
            mealTimeType: .lunch,
            notificationTime: lunchTime,
            isEnabled: false
        )
    }
    
    static var dinnerDefault: TimeNotificationStatus {
        // GMT+9 기준 오늘자 오후 5시 반
        let dinnerTime = Calendar.current.date(
            bySettingHour: 17,
            minute: 30,
            second: 0,
            of: Date()
        )!
        
        return .init(
            mealTimeType: .dinner,
            notificationTime: dinnerTime,
            isEnabled: false
        )
    }
    
    func show() {
        print("알림 설정 - \(mealTimeType.rawValue.capitalized): \(isEnabled ? "활성화" : "비활성화"), 시간: \(notificationTime?.description(with: .current) ?? "없음")")
    }
    
    static func == (lhs: TimeNotificationStatus, rhs: TimeNotificationStatus) -> Bool {
        return lhs.mealTimeType == rhs.mealTimeType &&
               lhs.notificationTime == rhs.notificationTime &&
               lhs.isEnabled == rhs.isEnabled
    }
}

struct SettingsScreen: View {
    @State private var lunchTimeNotificationStatus: TimeNotificationStatus = .lunchDefault
    @State private var dinnerTimeNotificationStatus: TimeNotificationStatus = .dinnerDefault
    @State private var isOnWeekMealUpdateNotification: Bool = true
    
    @State private var showLunchTimePicker = false
    @State private var showDinnerTimePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("알림") {
                    HStack(spacing: 20) {
                        Image(systemName: "sun.max.fill")
                            .frame(width: 20)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading) {
                            Text("중식 알림")
                                .font(.headline)
                            
                            HStack(spacing: 4) {
                                Text(lunchTimeNotificationStatus.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .onTapGesture {
                                showLunchTimePicker = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $lunchTimeNotificationStatus.isEnabled) {}
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "moon.fill")
                            .frame(width: 20)
                            .foregroundStyle(.indigo)
                        
                        VStack(alignment: .leading) {
                            Text("석식 알림")
                                .font(.headline)
                            
                            HStack(spacing: 4) {
                                Text(dinnerTimeNotificationStatus.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .onTapGesture {
                                showDinnerTimePicker = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $dinnerTimeNotificationStatus.isEnabled) {}
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "calendar.badge")
                            .frame(width: 20)
                            .foregroundStyle(.green)
                        
                        VStack(alignment: .leading) {
                            Text("주간 식단 업데이트 알림")
                                .font(.headline)
                            
                            Text("매주 월요일 오전 7시에 이번 주 식단이 업데이트됩니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $isOnWeekMealUpdateNotification) {}
                    }
                }
                
                Section("앱 정보") {
                    HStack(spacing: 20) {
                        Image(systemName: "graduationcap")
                            .frame(width: 20)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("교대학식")
                                .font(.headline)
                            
                            Text("버전 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "info.circle")
                            .frame(width: 20)
                            .foregroundStyle(.blue)
                        
                        NavigationLink {
                            OpenSourceUsageScreen()
                        } label: {
                            Text("오픈소스 라이선스")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLunchTimePicker) {
                TimeDatePickerModal(
                    initialTime: lunchTimeNotificationStatus.notificationTime ?? .now
                ) { selectedTime in
                    var updated = lunchTimeNotificationStatus
                    updated.notificationTime = selectedTime
                    lunchTimeNotificationStatus = updated
                }
                .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showDinnerTimePicker) {
                TimeDatePickerModal(
                    initialTime: dinnerTimeNotificationStatus.notificationTime ?? .now
                ) { selectedTime in
                    var updated = dinnerTimeNotificationStatus
                    updated.notificationTime = selectedTime
                    dinnerTimeNotificationStatus = updated
                }
                .presentationDetents([.fraction(0.4)])
            }
        }
    }
}

#Preview {
    SettingsScreen()
}
