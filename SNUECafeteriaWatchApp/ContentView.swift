//
//  ContentView.swift
//  SNUECafeteriaWatchApp
//

import PlatformSwiftUI
import SwiftUI
import WatchConnectivityKit
import KSTDateKit

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

    var navigationTitle: String {
        switch self {
        case .todayTomorrow: "오늘의 식단"
        case .weekly: "이번 주 식단"
        }
    }
}

private enum WatchListModeTransition {
    static let fadeOut = ContentFadeTransition.fadeOut
    static let fadeIn = ContentFadeTransition.fadeIn
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = WatchMealStore()
    @State private var navigation = WatchNavigationState.shared
    @State private var listMode: WatchMealListMode = .todayTomorrow
    @State private var listContentOpacity = 1.0
    @State private var isModeTransitioning = false
    @State private var isShareSheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Group {
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
                    .opacity(listContentOpacity)
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
                            toggleListModePreservingScroll(proxy: proxy)
                        } label: {
                            Image(systemName: listMode.toolbarSystemImage)
                        }
                        .accessibilityLabel(listMode.toolbarAccessibilityLabel)
                        .disabled(isModeTransitioning)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            isShareSheetPresented = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("식단 공유")
                        .disabled(!store.hasCachedMeals)
                    }
                }
            }
            .navigationTitle(listMode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShareSheetPresented) {
                if let meal = shareTargetMeal {
                    NavigationStack {
                        WatchShareSheet(meal: meal)
                    }
                }
            }
        }
        .task {
            WatchCompanionSyncService.shared.onPayloadUpdated = { @MainActor in
                store.reload()
                WidgetTimelineReload.requestAll()
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

    private var shareTargetMeal: CachedDayMeal? {
        let today = Calendar.kst.startOfDay(for: .now)
        if let highlight = navigation.highlightRequest,
           let meal = store.meal(for: highlight.date) {
            return meal
        }
        return store.meal(for: today)
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

    /// 목록 모드를 바꾼 뒤 짧은 페이드로 전환하고 glow 대상으로 즉시 스크롤한다.
    private func toggleListModePreservingScroll(proxy: ScrollViewProxy) {
        guard !isModeTransitioning else { return }
        isModeTransitioning = true
        let previousHighlight = navigation.highlightRequest

        withAnimation(.easeOut(duration: WatchListModeTransition.fadeOut)) {
            listContentOpacity = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(WatchListModeTransition.fadeOut * 1000)))
            var transaction = Transaction()
            transaction.animation = nil
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                listMode.toggle()
                listContentOpacity = 0
            }
            let target = resolvedScrollRequest(preferring: previousHighlight)
            navigation.updateHighlight(on: target.date, mealType: target.mealType)
            await Task.yield()
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(Int(ContentFadeTransition.layoutSettle * 1000)))
            scroll(to: target, proxy: proxy, animated: false)
            withAnimation(.easeIn(duration: WatchListModeTransition.fadeIn)) {
                listContentOpacity = 1
            }
            try? await Task.sleep(for: .milliseconds(Int(WatchListModeTransition.fadeIn * 1000)))
            isModeTransitioning = false
        }
    }

    private func scrollToCurrentMeal() {
        guard let request = currentMealRequest() else { return }
        navigation.openMeal(on: request.date, mealType: request.mealType)
    }

    /// 선호 대상의 스크롤 ID를 현재 목록에서 찾을 수 없으면 오늘 중식/석식으로 대체한다.
    private func resolvedScrollRequest(
        preferring preferred: WatchNavigationRequest?
    ) -> WatchNavigationRequest {
        if let preferred, isScrollTargetAvailable(preferred) {
            return preferred
        }
        if let current = currentMealRequest() {
            return current
        }
        let today = Calendar.kst.startOfDay(for: .now)
        return WatchNavigationRequest(date: today, mealType: .lunch)
    }

    /// 현재 표시 목록에 해당 날짜(및 식사 카드) 스크롤 ID가 존재하는지 판별한다.
    private func isScrollTargetAvailable(_ request: WatchNavigationRequest) -> Bool {
        guard displayDates.contains(where: { Calendar.kst.isDate($0, inSameDayAs: request.date) }) else {
            return false
        }
        // 식사 카드 ID는 meal 데이터가 있을 때만 뷰에 붙는다.
        if request.mealType != nil {
            return store.meal(for: request.date) != nil
        }
        return true
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

        let fallback = MealSchedule.fallbackMealType(
            hasLunch: todayMeal.hasLunch,
            hasDinner: todayMeal.hasDinner,
            at: now
        )
        return WatchNavigationRequest(date: today, mealType: fallback)
    }

    private func scroll(
        to request: WatchNavigationRequest,
        proxy: ScrollViewProxy,
        animated: Bool = true
    ) {
        let target = resolvedScrollRequest(preferring: request)
        if target != request {
            navigation.updateHighlight(on: target.date, mealType: target.mealType)
        }

        let dayID = WatchMealScrollID.day(date: target.date)
        let targetID: String
        if let mealType = target.mealType, store.meal(for: target.date) != nil {
            targetID = WatchMealScrollID.meal(date: target.date, mealType: mealType)
        } else {
            targetID = dayID
        }

        let scroll = {
            proxy.scrollTo(dayID, anchor: .top)
            proxy.scrollTo(targetID, anchor: .top)
        }

        if animated {
            withAnimation { scroll() }
        } else {
            scroll()
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
