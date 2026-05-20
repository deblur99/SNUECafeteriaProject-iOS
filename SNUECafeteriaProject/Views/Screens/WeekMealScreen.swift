//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

// MARK: - Supporting Types

private enum DragAxis { case horizontal, vertical }

// MARK: - Week Pane View

/// anchorDate 기준 한 주의 콘텐츠 pane. 주차별 스크롤 위치 자동 기억·복원.
private struct WeekPaneView: View {
    let days: [Date]
    /// get: 저장된 날짜 반환. 없으면 첫 날(월요일)로 이동.
    ///      nil을 반환하면 ScrollView가 이전 주의 offset을 그대로 유지(scroll bleeding)하므로
    ///      미방문 주차도 명시적으로 첫 날을 지정해 최상단을 보장한다.
    /// set: center pane(현재 선택된 주차)이고 유효한 날짜인 경우만 저장.
    ///      off-screen pane의 SET 이벤트도 차단해 기존 저장 위치 덮어쓰기 방지.
    @Binding var scrollPosition: Date?
    var dragAxis: DragAxis?
    var isNavigating: Bool

    @Environment(MealStore.self) private var mealStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if days.isEmpty {
            ContentUnavailableView(
                "식단 정보 없음",
                systemImage: "fork.knife",
                description: Text("해당 주의 식단 정보가 없습니다.")
            )
        } else {
            GeometryReader { geometry in
                let columns = gridColumns(for: geometry.size.width)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(days, id: \.self) { date in
                            let day = Calendar.kst.startOfDay(for: date)
                            DayMealCard(
                                date: day,
                                dayMeal: mealStore.meal(for: day),
                                preferredColumns: columns.count >= 2 ? 1 : nil
                            )
                            .frame(maxHeight: .infinity, alignment: .top)
                            .id(date)
                        }
                    }
                    .scrollTargetLayout()
                    .padding()
                }
                // scrollPosition.get이 days.first를 fallback으로 반환하므로
                // .id(weekStartDate)로 강제 재생성 없이도 scroll bleeding이 발생하지 않는다
                .scrollPosition(id: $scrollPosition, anchor: .top)
                .scrollDisabled(dragAxis == .horizontal || isNavigating)
            }
        }
    }

    /// 너비와 size class 기반으로 열 레이아웃을 결정
    /// - iPhone 세로 (< 500pt): 1열
    /// - iPhone 가로 (≥ 500pt): 2열
    /// - iPad 미니 세로 (< 768pt): 1열
    /// - iPad 세로 / iPad 미니 가로 (768pt ~ 1099pt): 2열
    /// - iPad 가로 (≥ 1100pt): 3열
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let count: Int
        if (horizontalSizeClass ?? .compact) == .compact {
            count = width >= 500 ? 2 : 1
        } else {
            count = width >= 1100 ? 3 : (width >= 768 ? 2 : 1)
        }
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
}

// MARK: - Screen

struct WeekMealScreen: View {
    @Environment(MealStore.self) private var mealStore
    @State private var selectedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var isSheetPresented: Bool = false
    /// 주차별 스크롤 위치 (키: 주의 시작일, 값: 뷰포트 상단에 위치한 날짜)
    /// - 사용자 스크롤: LazyVGrid에 scrollTargetLayout()를 달면 partial-visible 카드도 추적
    /// - 시트/툴바 이동: 해당 날짜를 직접 저장 → scrollPosition(id:anchor:)로 이동
    @State private var scrollPositions: [Date: Date] = [:]
    /// 드래그 또는 애니메이션 전환 중인 수평 오프셋
    @State private var dragOffset: CGFloat = 0
    /// GeometryReader에서 측정한 뷰 너비 (초기값: iPhone 기본 너비)
    @State private var viewWidth: CGFloat = 390
    @State private var isNavigating: Bool = false
    /// 스크롤 중 방향 가져와서 ScrollView의 스크롤을 방지하며 좌우 전환하도록 해주는 상태 변수
    @State private var dragAxis: DragAxis? = nil
    /// 툴바/시트 전환 시 인접 pane에 표시할 임시 목적지 날짜
    @State private var transitionDate: Date? = nil
    /// 전환 중 입력된 다음 스와이프 방향 (true: 다음 주, false: 이전 주)
    @State private var pendingNavigation: Bool? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                // 3-pane HStack: [이전 주 | 현재 주 | 다음 주]
                // offset(x: -w) 기준으로 현재 주(item[1])를 화면에 표시
                // dragOffset이 변함에 따라 인접 pane이 실시간으로 슬라이드됨
                HStack(spacing: 0) {
                    weekPaneView(for: prevPaneDate).frame(width: geo.size.width)
                    weekPaneView(for: selectedDate).frame(width: geo.size.width)
                    weekPaneView(for: nextPaneDate).frame(width: geo.size.width)
                }
                .offset(x: -geo.size.width + dragOffset)
                .onAppear { viewWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, new in
                    viewWidth = new
                    dragOffset = 0
                }
            }
            .clipped()
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(isPresented: $isSheetPresented) {
                WeekDatePickerModal(
                    initialDate: selectedDate,
                    availableDates: mealStore.availableDates
                ) { date in
                    let newDate = Calendar.kst.startOfDay(for: date)
                    // 목적지 주의 스크롤 위치를 해당 날짜 카드로 미리 지정
                    scrollPositions[weekStart(for: newDate)] = newDate
                    navigateTo(newDate)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // 첫 이벤트: 방향만 결정하고 offset은 아직 건드리지 않음
                        // isNavigating 여부와 관계없이 항상 축을 결정해야
                        // 두 번째 제스처의 onEnded에서 축 정보가 nil이 되는 문제를 방지
                        if dragAxis == nil {
                            let h = abs(value.translation.width)
                            let v = abs(value.translation.height)
                            dragAxis = h > v ? .horizontal : .vertical
                            print("Drag started. Axis: \(dragAxis!), translation: \(value.translation)")
                            return
                        }
                        guard !isNavigating else { return }
                        guard dragAxis == .horizontal else { return }
                        let dx = value.translation.width
                        // 해당 방향에 데이터가 없으면 드래그 차단
                        if dx > 0 && nearestPrevDate == nil { return }
                        if dx < 0 && nearestNextDate == nil { return }
                        dragOffset = dx
                        print("Dragging. Axis: \(dragAxis!), translation: \(value.translation), offset: \(dragOffset)")
                    }
                    .onEnded { value in
                        print("Drag ended. translation: \(value.translation), velocity: \(value.velocity)")
                        let axis = dragAxis
                        dragAxis = nil

                        let translation = value.translation.width
                        let velocity = value.velocity.width
                        let posThreshold = viewWidth * 0.35
                        let velThreshold: CGFloat = 500
                        let shouldGoForward = axis == .horizontal && (translation < -posThreshold || velocity < -velThreshold)
                        let shouldGoBackward = axis == .horizontal && (translation > posThreshold || velocity > velThreshold)

                        if isNavigating {
                            // 전환 중 발생한 스와이프는 큐에 저장해 전환 완료 후 즉시 실행
                            if shouldGoForward { pendingNavigation = true }
                            else if shouldGoBackward { pendingNavigation = false }
                            return
                        }

                        if shouldGoForward {
                            commitNavigation(forward: true)
                            print("Commit navigation forward. translation: \(translation), velocity: \(velocity)")
                        } else if shouldGoBackward {
                            commitNavigation(forward: false)
                            print("Commit navigation backward. translation: \(translation), velocity: \(velocity)")
                        } else {
                            withAnimation(.spring(bounce: 0)) { dragOffset = 0 }
                            print("Snap back. translation: \(translation), velocity: \(velocity)")
                        }
                    }
            )
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .title) {
            WeekSelectorView(
                selectedDate: Binding(
                    get: { selectedDate },
                    set: { navigateTo($0) }
                ),
                availableDates: mealStore.availableDates
            )
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("날짜 선택", systemImage: "calendar") {
                isSheetPresented.toggle()
            }
        }
    }
}

// MARK: - Navigation

private extension WeekMealScreen {
    /// 현재 주보다 이전 주 중 데이터가 있는 가장 가까운 날짜
    var nearestPrevDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealStore.availableDates.filter { $0 < interval.start }.max()
    }

    /// 현재 주보다 이후 주 중 데이터가 있는 가장 가까운 날짜
    var nearestNextDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealStore.availableDates.filter { $0 >= interval.end }.min()
    }

    /// 이전 pane에 표시할 날짜: 툴바/시트 전환 시 목적지가 이전 주이면 해당 날짜를 사용
    var prevPaneDate: Date {
        if let t = transitionDate, t < selectedDate { return t }
        return nearestPrevDate ?? Calendar.kst.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
    }

    /// 다음 pane에 표시할 날짜: 툴바/시트 전환 시 목적지가 다음 주이면 해당 날짜를 사용
    var nextPaneDate: Date {
        if let t = transitionDate, t > selectedDate { return t }
        return nearestNextDate ?? Calendar.kst.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
    }

    /// 드래그 제스처 완료 후 데이터가 있는 가장 가까운 주로 페이지 전환
    /// 해당 방향에 데이터가 없으면 원위치로 스냅백
    func commitNavigation(forward: Bool) {
        guard !isNavigating else { return }
        guard let targetDate = forward ? nearestNextDate : nearestPrevDate else {
            withAnimation(.spring) { dragOffset = 0 }
            return
        }
        isNavigating = true
        // bounce: 0 → 오버슈트 없이 부드럽게 슬라이드 완료
        withAnimation(.spring(duration: 0.3, bounce: 0)) {
            dragOffset = forward ? -viewWidth : viewWidth
        }
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            await MainActor.run {
                let pending = pendingNavigation
                // animation: nil → scrollPosition(id:)
                withTransaction(Transaction(animation: nil)) {
                    selectedDate = Calendar.kst.startOfDay(for: targetDate)
                    dragOffset = 0
                    isNavigating = false
                    pendingNavigation = nil
                }
                // 전환 중 입력된 다음 스와이프가 있으면 즉시 연속 실행
                if let next = pending {
                    commitNavigation(forward: next)
                }
            }
        }
    }

    /// 툴바/시트에서 임의 날짜로 슬라이드 전환
    /// transitionDate로 인접 pane 내용을 목적지로 덮어쓴 후 슬라이드 인
    func navigateTo(_ newDate: Date) {
        guard !isNavigating else { return }
        let target = Calendar.kst.startOfDay(for: newDate)
        guard target != selectedDate else { return }
        let forward = target > selectedDate
        isNavigating = true
        transitionDate = target
        withAnimation(.spring) {
            dragOffset = forward ? -viewWidth : viewWidth
        }
        Task {
            try? await Task.sleep(for: .seconds(0.31))
            await MainActor.run {
                withTransaction(Transaction(animation: nil)) {
                    transitionDate = nil
                    selectedDate = target
                    dragOffset = 0
                    isNavigating = false
                }
            }
        }
    }
}

// MARK: - Helpers

private extension WeekMealScreen {
    func weekStart(for date: Date) -> Date {
        Calendar.kstWeekInterval(for: date)?.start ?? date
    }

    func weekDays(for anchorDate: Date) -> [Date] {
        guard let interval = Calendar.kstWeekInterval(for: anchorDate) else { return [] }
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            guard let next = Calendar.kst.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    /// anchorDate 기준 WeekPaneView를 생성한다.
    /// scrollPositionBinding(for:)을 주입해 스크롤 위치를 주차별로 독립적으로 관리한다.
    func weekPaneView(for anchorDate: Date) -> some View {
        WeekPaneView(
            days: weekDays(for: anchorDate),
            scrollPosition: scrollPositionBinding(for: anchorDate),
            dragAxis: dragAxis,
            isNavigating: isNavigating
        )
    }

    /// 주차별 스크롤 위치 Binding을 반환한다.
    /// - get: 저장된 날짜, 없으면 weekStart(월요일)를 fallback으로 반환
    /// - set: center pane(현재 선택된 주차)의 이벤트만 저장해 off-screen 덮어쓰기를 방지
    func scrollPositionBinding(for anchorDate: Date) -> Binding<Date?> {
        let weekStartDate = weekStart(for: anchorDate)
        let days = weekDays(for: anchorDate)
        return Binding<Date?>(
            get: { scrollPositions[weekStartDate] ?? days.first },
            set: { newDate in
                guard let d = newDate else { return }
                guard weekStartDate == weekStart(for: selectedDate) else { return }
                scrollPositions[weekStartDate] = d
            }
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mealStore = MealStore()
    let container = DayMealPreviewHelper.previewContainer(type: .normal)

    WeekMealScreen()
        .environment(mealStore)
        .onAppear {
            do {
                try mealStore.load(modelContext: ModelContext(container))
            } catch {
                print("Failed to load preview data: \(error)")
            }
        }
}
