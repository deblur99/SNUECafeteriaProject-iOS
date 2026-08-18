//
//  ContentView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI
import UIKit
import SNUECafeteriaSharedIntents

enum AppTab: Hashable {
    case today, week, settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var todayPage: ShowingMeal = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘", systemImage: "sun.max", value: AppTab.today) {
                TodayMealScreen(showingMeal: $todayPage)
            }

            Tab("주간", systemImage: "calendar", value: AppTab.week) {
                WeekMealScreen()
            }

            Tab("설정", systemImage: "gear", value: AppTab.settings) {
                SettingsScreen()
            }
        }
        .task {
            // 킬 상태에서 알림으로 진입한 경우 오늘 탭으로 이동
            if let delegate = UIApplication.shared.delegate as? AppDelegate,
               delegate.pendingOpenTodayTab {
                selectedTab = .today
                delegate.pendingOpenTodayTab = false
            }
            applyPendingIntentNavigation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            applyPendingIntentNavigation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTodayTab)) { _ in
            selectedTab = .today
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAppTab)) { notification in
            guard let rawValue = notification.object as? String else { return }
            applyTabNavigation(rawValue: rawValue)
        }
        .onOpenURL { url in
            guard url.scheme == "snuecafeteria" else { return }
            switch url.host {
            case "today":
                selectedTab = .today
                todayPage = .today
            case "tomorrow":
                selectedTab = .today
                todayPage = .tomorrow
            default:
                break
            }
        }
    }

    private func applyPendingIntentNavigation() {
        let key = AppGroupsConfig.NavigationKeys.pendingNavigationTab
        guard let rawValue = UserDefaults.standard.string(forKey: key) else { return }
        UserDefaults.standard.removeObject(forKey: key)
        applyTabNavigation(rawValue: rawValue)
    }

    private func applyTabNavigation(rawValue: String) {
        switch rawValue {
        case AppTabSelection.today.rawValue:
            selectedTab = .today
            todayPage = .today
        case AppTabSelection.week.rawValue:
            selectedTab = .week
        case AppTabSelection.settings.rawValue:
            selectedTab = .settings
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .dayMealPreview(type: .normal)
}
