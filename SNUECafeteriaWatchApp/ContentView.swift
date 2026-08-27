//
//  ContentView.swift
//  SNUECafeteriaWatchApp
//

import SwiftUI
import WatchConnectivityKit

private enum WatchMealListMode {
    case todayTomorrow
    case weekly

    mutating func toggle() {
        self = self == .todayTomorrow ? .weekly : .todayTomorrow
    }

    var toolbarSystemImage: String {
        switch self {
        case .todayTomorrow: "calendar"
        case .weekly: "sun.max"
        }
    }

    var toolbarAccessibilityLabel: String {
        switch self {
        case .todayTomorrow: "일자별 목록 보기"
        case .weekly: "오늘 내일 목록 보기"
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = WatchMealStore()
    @State private var navigation = WatchNavigationState.shared
    @State private var listMode: WatchMealListMode = .todayTomorrow

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    if store.hasCachedMeals {
                        WatchMealListView(
                            dates: displayDates,
                            store: store,
                            highlightedMealType: highlightedMealType(for:)
                        )
                    } else {
                        WatchMealEmptyStateView()
                    }
                }
                .onChange(of: navigation.scrollToken) { _, _ in
                    guard let request = navigation.pendingScrollRequest else { return }
                    prepareListMode(for: request.date)
                    let target = request
                    navigation.clearPendingScroll()
                    // listMode 전환·레이아웃 반영 뒤에 스크롤해야 ID가 존재한다.
                    Task { @MainActor in
                        await Task.yield()
                        scroll(to: target, proxy: proxy)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            scrollToCurrentMeal()
                        } label: {
                            Image(systemName: "location.fill")
                        }
                        .accessibilityLabel("현재 식단으로 이동")
                        .disabled(!store.hasCachedMeals)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            listMode.toggle()
                        } label: {
                            Image(systemName: listMode.toolbarSystemImage)
                        }
                        .accessibilityLabel(listMode.toolbarAccessibilityLabel)
                    }
                }
            }
            .navigationTitle("식단")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            WatchCompanionSyncService.shared.onPayloadUpdated = { @MainActor in
                store.reload()
            }
            await WatchMealDataCoordinator.shared.sync(store: store)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await WatchMealDataCoordinator.shared.sync(store: store) }
        }
    }

    private var displayDates: [Date] {
        switch listMode {
        case .todayTomorrow:
            let today = Calendar.kst.startOfDay(for: .now)
            let tomorrow = Calendar.kst.date(byAdding: .day, value: 1, to: today) ?? today
            return [today, tomorrow]
        case .weekly:
            return Calendar.kstDatesInWeek()
        }
    }

    private func highlightedMealType(for date: Date) -> MealType? {
        guard let highlight = navigation.highlightRequest,
              Calendar.kst.isDate(highlight.date, inSameDayAs: date)
        else { return nil }
        return highlight.mealType
    }

    private func prepareListMode(for date: Date) {
        let isTodayOrTomorrow =
            Calendar.kst.isDateInToday(date) || Calendar.kst.isDateInTomorrow(date)
        if !isTodayOrTomorrow, listMode == .todayTomorrow {
            listMode = .weekly
        }
    }

    private func scrollToCurrentMeal() {
        guard let request = currentMealRequest() else { return }
        navigation.openMeal(on: request.date, mealType: request.mealType)
    }

    /// 현재 시점의 오늘 중식/석식 대상으로 스크롤 요청을 만든다.
    private func currentMealRequest(at now: Date = .now) -> WatchNavigationRequest? {
        let today = Calendar.kst.startOfDay(for: now)
        guard displayDates.contains(where: { Calendar.kst.isDate($0, inSameDayAs: today) }) else {
            return nil
        }

        if let nearest = AppGroupMealCache.nearestMeal(from: now) {
            return WatchNavigationRequest(date: today, mealType: nearest.type)
        }

        guard let todayMeal = store.meal(for: today) else {
            return WatchNavigationRequest(date: today, mealType: nil)
        }

        if todayMeal.hasLunch {
            let lunchEnd = Calendar.kst.date(bySettingHour: 13, minute: 20, second: 0, of: now)!
            if now <= lunchEnd {
                return WatchNavigationRequest(date: today, mealType: .lunch)
            }
        }

        if todayMeal.hasDinner {
            let dinnerEnd = Calendar.kst.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
            if now <= dinnerEnd {
                return WatchNavigationRequest(date: today, mealType: .dinner)
            }
        }

        if todayMeal.hasLunch {
            return WatchNavigationRequest(date: today, mealType: .lunch)
        }
        if todayMeal.hasDinner {
            return WatchNavigationRequest(date: today, mealType: .dinner)
        }
        return WatchNavigationRequest(date: today, mealType: nil)
    }

    private func scroll(to request: WatchNavigationRequest, proxy: ScrollViewProxy) {
        let dayID = WatchMealScrollID.day(date: request.date)
        let targetID: String
        if let mealType = request.mealType {
            targetID = WatchMealScrollID.meal(date: request.date, mealType: mealType)
        } else {
            targetID = dayID
        }

        // 날짜 섹션을 먼저 맞춘 뒤 식사 카드로 이동하면 레이아웃이 더 안정적이다.
        proxy.scrollTo(dayID, anchor: .top)
        withAnimation {
            proxy.scrollTo(targetID, anchor: .top)
        }
    }
}

private struct WatchMealListView: View {
    let dates: [Date]
    let store: WatchMealStore
    let highlightedMealType: (Date) -> MealType?

    var body: some View {
        // LazyVStack은 화면 밖 행을 만들지 않아 ScrollViewReader.scrollTo ID가
        // 등록되지 않는다. 워치 주간 목록 규모에서는 VStack이 적합하다.
        VStack(alignment: .leading, spacing: 20) {
            ForEach(dates, id: \.self) { date in
                WatchMealDaySectionView(
                    date: date,
                    meal: store.meal(for: date),
                    highlightedMealType: highlightedMealType(date)
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }
}

private struct WatchMealEmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("식단 정보 없음")
                .font(.headline)
            Text("네트워크 연결을 확인하거나\niPhone 앱과 동기화해 주세요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
    }
}

#Preview {
    ContentView()
}
