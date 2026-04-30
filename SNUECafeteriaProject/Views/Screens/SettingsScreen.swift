//
//  SettingsScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

/// AppStorage 지원을 위한 RawRepresentable 확장
extension TimeNotificationStatus: RawRepresentable {
    var rawValue: String {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let value = try? JSONDecoder().decode(Self.self, from: data)
        else { return nil }
        self = value
    }
}

/// 식사 알림 설정 모델
nonisolated struct TimeNotificationStatus: Codable, Equatable {
    let mealTimeType: MealTimeType
    var notificationTime: Date?
    var isEnabled: Bool

    nonisolated enum MealTimeType: String, Codable {
        case lunch, dinner
    }

    // RawRepresentable where RawValue: Encodable 의 stdlib default encode(to:)가
    // rawValue getter를 호출해 무한 재귀를 일으키지 않도록 명시적으로 구현.
    private enum CodingKeys: String, CodingKey {
        case mealTimeType, notificationTime, isEnabled
    }

    init(mealTimeType: MealTimeType, notificationTime: Date? = nil, isEnabled: Bool) {
        self.mealTimeType = mealTimeType
        self.notificationTime = notificationTime
        self.isEnabled = isEnabled
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mealTimeType, forKey: .mealTimeType)
        try container.encodeIfPresent(notificationTime, forKey: .notificationTime)
        try container.encode(isEnabled, forKey: .isEnabled)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mealTimeType = try container.decode(MealTimeType.self, forKey: .mealTimeType)
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
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

/// 설정 화면: 식사 알림 설정과 앱 정보 표시
struct SettingsScreen: View {
    @AppStorage("lunchNotificationStatus") private var lunchTimeNotificationStatus: TimeNotificationStatus = .lunchDefault
    @AppStorage("dinnerNotificationStatus") private var dinnerTimeNotificationStatus: TimeNotificationStatus = .dinnerDefault
    @AppStorage("weeklyNotificationEnabled") private var isOnWeekMealUpdateNotification: Bool = false

    @State private var showLunchTimePicker = false
    @State private var showDinnerTimePicker = false

    @Environment(\.scenePhase) private var scenePhase
    @State private var showNotificationPermission = false
    @State private var notificationPermissionMode: NotificationPermissionScreen.Mode = .request
    @State private var pendingMealType: TimeNotificationStatus.MealTimeType? = nil
    @State private var pendingWeekly = false

    var body: some View {
        NavigationStack {
            Form {
                Section("알림") {
                    HStack(spacing: 20) {
                        Image(systemName: "sun.max.fill")
                            .frame(width: 20)
                            .foregroundStyle(.lunch)
                        
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
                            .onChange(of: lunchTimeNotificationStatus.isEnabled) { _, isOn in
                                guard isOn else {
                                    NotificationService.shared.cancel(for: .lunch)
                                    return
                                }
                                Task { await handleNotificationToggle(for: .lunch) }
                            }
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "moon.fill")
                            .frame(width: 20)
                            .foregroundStyle(.dinner)
                        
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
                            .onChange(of: dinnerTimeNotificationStatus.isEnabled) { _, isOn in
                                guard isOn else {
                                    NotificationService.shared.cancel(for: .dinner)
                                    return
                                }
                                Task { await handleNotificationToggle(for: .dinner) }
                            }
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "calendar.badge")
                            .frame(width: 20)
                            .foregroundStyle(.green)
                        
                        VStack(alignment: .leading) {
                            Text("주간 식단 업데이트 알림")
                                .font(.headline)
                            
                            Text("매주 월요일 오전 9시에 이번 주 식단이 업데이트됩니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $isOnWeekMealUpdateNotification) {}
                            .onChange(of: isOnWeekMealUpdateNotification) { _, isOn in
                                guard isOn else {
                                    NotificationService.shared.cancelWeekly()
                                    return
                                }
                                Task { await handleWeeklyNotificationToggle() }
                            }
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
            .navigationTitle("설정")
            .sheet(isPresented: $showLunchTimePicker) {
                TimeDatePickerModal(
                    initialTime: lunchTimeNotificationStatus.notificationTime ?? .now
                ) { selectedTime in
                    lunchTimeNotificationStatus.notificationTime = selectedTime
                    if lunchTimeNotificationStatus.isEnabled {
                        NotificationService.shared.schedule(for: .lunch, at: selectedTime)
                    }
                }
                .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showDinnerTimePicker) {
                TimeDatePickerModal(
                    initialTime: dinnerTimeNotificationStatus.notificationTime ?? .now
                ) { selectedTime in
                    dinnerTimeNotificationStatus.notificationTime = selectedTime
                    if dinnerTimeNotificationStatus.isEnabled {
                        NotificationService.shared.schedule(for: .dinner, at: selectedTime)
                    }
                }
                .presentationDetents([.fraction(0.4)])
            }
            .fullScreenCover(isPresented: $showNotificationPermission) {
                NotificationPermissionScreen(
                    initialMode: notificationPermissionMode,
                    onPermissionGranted: {
                        if let type = pendingMealType {
                            let time = type == .lunch
                                ? lunchTimeNotificationStatus.notificationTime
                                : dinnerTimeNotificationStatus.notificationTime
                            if let time {
                                NotificationService.shared.schedule(for: type, at: time)
                            }
                            pendingMealType = nil
                        }
                        if pendingWeekly {
                            NotificationService.shared.scheduleWeekly()
                            pendingWeekly = false
                        }
                    },
                    onCancel: {
                        if let type = pendingMealType {
                            switch type {
                            case .lunch: lunchTimeNotificationStatus.isEnabled = false
                            case .dinner: dinnerTimeNotificationStatus.isEnabled = false
                            }
                            pendingMealType = nil
                        }
                        if pendingWeekly {
                            isOnWeekMealUpdateNotification = false
                            pendingWeekly = false
                        }
                    }
                )
            }
            .task { await syncPermissionState() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await syncPermissionState() }
            }
        }
    }

    // MARK: - Helpers

    private func handleNotificationToggle(for type: TimeNotificationStatus.MealTimeType) async {
        let status = await NotificationService.shared.authorizationStatus
        switch status {
        case .authorized:
            let time = type == .lunch
                ? lunchTimeNotificationStatus.notificationTime
                : dinnerTimeNotificationStatus.notificationTime
            if let time {
                NotificationService.shared.schedule(for: type, at: time)
            }
        case .denied:
            pendingMealType = type
            notificationPermissionMode = .denied
            showNotificationPermission = true
        default:
            pendingMealType = type
            notificationPermissionMode = .request
            showNotificationPermission = true
        }
    }

    private func handleWeeklyNotificationToggle() async {
        let status = await NotificationService.shared.authorizationStatus
        switch status {
        case .authorized:
            NotificationService.shared.scheduleWeekly()
        case .denied:
            pendingWeekly = true
            notificationPermissionMode = .denied
            showNotificationPermission = true
        default:
            pendingWeekly = true
            notificationPermissionMode = .request
            showNotificationPermission = true
        }
    }

    private func syncPermissionState() async {
        let status = await NotificationService.shared.authorizationStatus
        guard status == .authorized else {
            lunchTimeNotificationStatus.isEnabled = false
            dinnerTimeNotificationStatus.isEnabled = false
            isOnWeekMealUpdateNotification = false
            return
        }
        // 권한이 있으면 활성화된 알림 재등록 (설정 앱에서 권한 복원 시 포함)
        if lunchTimeNotificationStatus.isEnabled, let time = lunchTimeNotificationStatus.notificationTime {
            NotificationService.shared.schedule(for: .lunch, at: time)
        }
        if dinnerTimeNotificationStatus.isEnabled, let time = dinnerTimeNotificationStatus.notificationTime {
            NotificationService.shared.schedule(for: .dinner, at: time)
        }
        if isOnWeekMealUpdateNotification {
            NotificationService.shared.scheduleWeekly()
        }
    }
}

#Preview {
    SettingsScreen()
}
