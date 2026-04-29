//
//  ContentView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI
import UIKit

enum AppTab: Hashable {
    case today, week, settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘", systemImage: "sun.max", value: AppTab.today) {
                TodayMealScreen()
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTodayTab)) { _ in
            selectedTab = .today
        }
    }
}

#Preview {
    ContentView()
}
