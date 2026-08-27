//
//  SNUECafeteriaMacApp.swift
//  SNUECafeteriaMac
//

import SwiftData
import SwiftUI

@main
struct SNUECafeteriaMacApp: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase
    @State private var errorMessage: String?
    @State private var mealRepository = MealRepository()
    @State private var services = ServiceContainer()

    @AppStorage("lunchNotificationStatus") private var lunchStatus: TimeNotificationStatus = .lunchDefault
    @AppStorage("dinnerNotificationStatus") private var dinnerStatus: TimeNotificationStatus = .dinnerDefault

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DayMeal.self, MenuItem.self])
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
                .environment(mealRepository)
                .environment(services)
                .frame(minWidth: 720, minHeight: 480)
                .alert(errorMessage ?? "", isPresented: .constant(errorMessage != nil)) {
                    Button("확인") { errorMessage = nil }
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 960, height: 640)
        .onChange(of: scenePhase) { _, newPhase in
            syncIfNeeded(newPhase)
        }
    }

    private func syncIfNeeded(_ scenePhase: ScenePhase) {
        guard scenePhase == .active else { return }

        Task { @MainActor in
            guard await services.network.isConnected() else {
                errorMessage = "네트워크 연결이 없습니다. 기존에 저장된 식단 정보를 가져옵니다."
                try? mealRepository.loadOffline(modelContainer: sharedModelContainer)
                return
            }

            await mealRepository.sync(using: sharedModelContainer)

            if lunchStatus.isEnabled, let time = lunchStatus.notificationTime {
                await services.notification.schedule(for: .lunch, at: time, meals: mealRepository.meals)
            }
            if dinnerStatus.isEnabled, let time = dinnerStatus.notificationTime {
                await services.notification.schedule(for: .dinner, at: time, meals: mealRepository.meals)
            }
        }
    }
}
