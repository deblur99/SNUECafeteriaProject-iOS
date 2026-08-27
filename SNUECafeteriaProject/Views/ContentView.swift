//
//  ContentView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum AppTab: Hashable {
    case today, week, settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var todayPage: ShowingMeal = .today

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("오늘", systemImage: "sun.max").tag(AppTab.today)
                Label("주간", systemImage: "calendar").tag(AppTab.week)
                Label("설정", systemImage: "gear").tag(AppTab.settings)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            detailContent
        }
        .task { handleLaunchNavigation() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            applyPendingIntentNavigation()
            consumePendingOpenTodayTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTodayTab)) { _ in
            selectedTab = .today
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAppTab)) { notification in
            guard let rawValue = notification.object as? String else { return }
            applyTabNavigation(rawValue: rawValue)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        #else
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
        .task { handleLaunchNavigation() }
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
            handleDeepLink(url)
        }
        #endif
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .today:
            TodayMealScreen(showingMeal: $todayPage)
        case .week:
            WeekMealScreen()
        case .settings:
            SettingsScreen()
        }
    }

    private func handleLaunchNavigation() {
        consumePendingOpenTodayTab()
        applyPendingIntentNavigation()
    }

    private func consumePendingOpenTodayTab() {
        #if os(iOS)
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           delegate.pendingOpenTodayTab {
            selectedTab = .today
            delegate.pendingOpenTodayTab = false
        }
        #elseif os(macOS)
        if let delegate = NSApp.delegate as? MacAppDelegate,
           delegate.pendingOpenTodayTab {
            selectedTab = .today
            delegate.pendingOpenTodayTab = false
        }
        #endif
    }

    private func handleDeepLink(_ url: URL) {
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
