//
//  ContentView.swift
//  SNUECafeteriaWatchApp
//

import SwiftUI
import WatchConnectivityKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = WatchMealStore()
    @State private var navigation = WatchNavigationState.shared

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    if store.hasCachedMeals {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(Calendar.kstDatesInWeek(), id: \.self) { date in
                                WatchMealDaySectionView(
                                    date: date,
                                    meal: store.meal(for: date),
                                    highlightedMealType: highlightedMealType(for: date)
                                )
                                .id(scrollID(for: date))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                    } else {
                        emptyState
                    }
                }
                .onChange(of: navigation.pendingScrollRequest) { _, request in
                    guard let request else { return }
                    scroll(to: request, proxy: proxy)
                    navigation.clearPendingScroll()
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

    private var emptyState: some View {
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

    private func highlightedMealType(for date: Date) -> MealType? {
        guard let highlight = navigation.highlightRequest,
              Calendar.kst.isDate(highlight.date, inSameDayAs: date)
        else { return nil }
        return highlight.mealType
    }

    private func scrollID(for date: Date) -> String {
        DateFormatter.kstDash.string(from: date)
    }

    private func scroll(to request: WatchNavigationRequest, proxy: ScrollViewProxy) {
        let id = scrollID(for: request.date)
        withAnimation {
            proxy.scrollTo(id, anchor: .top)
        }
    }
}

#Preview {
    ContentView()
}
