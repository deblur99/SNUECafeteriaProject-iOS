//
//  SNUECafeteriaProjectApp.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

// TODO: 앱 화면 진입할 때마다 아래 작업 수행하기
// 1) 로컬 저장 확인: 로컬에 데이터가 있는지 확인하고, 없으면 Firebase로부터 데이터 가져오기 시도
// 2) 날짜 비교: 로컬에 저장된 데이터의 날짜와 오늘 날짜 비교 (한국 표준시 기준)해서, 날짜가 다르면 Firebase로부터 데이터 가져오기 시도

@main
struct SNUECafeteriaProjectApp: App {
    /// Firebase 연동
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 포그라운드 변화 감지
    @Environment(\.scenePhase) private var scenePhase
    
    /// 오류 Alert 메시지 띄우기
    @State private var errorMessage: String? = nil
    
    // Stores
    @State private var mealStore = MealStore()
    
    // 알림 설정 (동기화 후 알림 재등록에 사용)
    @AppStorage("lunchNotificationStatus") private var lunchStatus: TimeNotificationStatus = .lunchDefault
    @AppStorage("dinnerNotificationStatus") private var dinnerStatus: TimeNotificationStatus = .dinnerDefault

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DayMeal.self,
            MenuItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mealStore)
                .alert(errorMessage ?? "", isPresented: .constant(errorMessage != nil)) {
                    Button("확인") {
                        errorMessage = nil
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            syncIfNeeded(newPhase)
        }
    }
    
}

extension SNUECafeteriaProjectApp {
    /// 포그라운드 진입이 감지되면 데이터 동기화하는 메서드
    private func syncIfNeeded(_ scenePhase: ScenePhase) {
        guard scenePhase == .active else { return }
        
        Task {
            guard await NetworkService.shared.isConnected() else {
                errorMessage = "네트워크 연결이 없습니다. 데이터 동기화를 건너뜁니다."
                print("네트워크 연결이 없습니다. 데이터 동기화를 건너뜁니다.")
                return
            }
            let modelContext = ModelContext(sharedModelContainer)
            await MealSyncService.syncIfNeeded(modelContext: modelContext)
            try? mealStore.load(modelContext: modelContext)
            
            // 새 식단 데이터 기준으로 알림 재등록
            if lunchStatus.isEnabled, let time = lunchStatus.notificationTime {
                await NotificationService.shared.schedule(for: .lunch, at: time, meals: mealStore.meals)
            }
            if dinnerStatus.isEnabled, let time = dinnerStatus.notificationTime {
                await NotificationService.shared.schedule(for: .dinner, at: time, meals: mealStore.meals)
            }
        }
    }
}
