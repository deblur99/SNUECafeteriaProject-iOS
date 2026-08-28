//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import PlatformSwiftUI
import SwiftData
import SwiftUI
import KSTDateKit

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

    @Environment(MealRepository.self) private var mealRepository
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if days.isEmpty {
            MealContentUnavailableView(
                title: "식단 정보 없음",
                systemImage: "fork.knife",
                description: "해당 주의 식단 정보가 없습니다."
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
                                dayMeal: mealRepository.meal(for: day),
                                isShareButtonContained: true,
                                preferredColumns: columns.count >= 2 ? 1 : nil,
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
                #if os(macOS)
                .transaction { $0.animation = nil }
                #endif
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
    @Environment(MealRepository.self) private var mealRepository
    @State private var selectedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var isSheetPresented: Bool = false
    /// 주차별 스크롤 위치 (키: 주의 시작일, 값: 뷰포트 상단에 위치한 날짜)
    @State private var scrollPositions: [Date: Date] = [:]
    /// 드래그 또는 애니메이션 전환 중인 수평 오프셋 (iOS 3-pane)
    @State private var dragOffset: CGFloat = 0
    @State private var viewWidth: CGFloat = 390
    @State private var isNavigating: Bool = false
    @State private var dragAxis: DragAxis? = nil
    /// 툴바/시트 전환 시 인접 pane에 표시할 임시 목적지 날짜 (iOS)
    @State private var transitionDate: Date? = nil
    @State private var pendingNavigation: Bool? = nil
    #if os(macOS)
    @State private var contentOpacity = 1.0
    #endif

    var body: some View {
        NavigationStack {
            weekContent
                .clipped()
                .background(Color.groupedBackground)
                .inlineNavigationTitle()
                .toolbar(content: toolbarContent)
                .modifier(WeekDatePickerPresentation(
                    isPresented: $isSheetPresented,
                    selectedDate: selectedDate,
                    availableDates: mealRepository.availableDates,
                    onSelect: applyDatePickerSelection
                ))
                .simultaneousGesture(weekSwipeGesture)
        }
    }

    @ViewBuilder
    private var weekContent: some View {
        #if os(iOS)
        GeometryReader { geo in
            // iOS: 3-pane 슬라이드 — 세로 ScrollView와 축 분리로 기존 스크롤 유지
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
        #else
        GeometryReader { geo in
            weekPaneView(for: selectedDate)
                .id(weekStart(for: selectedDate))
                .animation(nil, value: weekStart(for: selectedDate))
                .frame(width: geo.size.width)
                .opacity(contentOpacity)
                .onAppear { viewWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, new in
                    viewWidth = new
                }
        }
        #endif
    }

    private var weekSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if dragAxis == nil {
                    let h = abs(value.translation.width)
                    let v = abs(value.translation.height)
                    dragAxis = h > v ? .horizontal : .vertical
                    return
                }
                #if os(iOS)
                guard !isNavigating else { return }
                guard dragAxis == .horizontal else { return }
                let dx = value.translation.width
                if dx > 0 && nearestPrevDate == nil { return }
                if dx < 0 && nearestNextDate == nil { return }
                dragOffset = dx
                #endif
            }
            .onEnded { value in
                let axis = dragAxis
                dragAxis = nil

                let translation = value.translation.width
                let velocity = value.velocity.width
                let posThreshold = viewWidth * 0.35
                let velThreshold: CGFloat = 500
                let shouldGoForward = axis == .horizontal && (translation < -posThreshold || velocity < -velThreshold)
                let shouldGoBackward = axis == .horizontal && (translation > posThreshold || velocity > velThreshold)

                if isNavigating {
                    if shouldGoForward { pendingNavigation = true }
                    else if shouldGoBackward { pendingNavigation = false }
                    return
                }

                if shouldGoForward {
                    commitNavigation(forward: true)
                } else if shouldGoBackward {
                    commitNavigation(forward: false)
                } else {
                    #if os(iOS)
                    withAnimation(.spring(bounce: 0)) { dragOffset = 0 }
                    #endif
                }
            }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            WeekSelectorView(
                selectedDate: Binding(
                    get: { selectedDate },
                    set: { navigateTo($0) }
                ),
                availableDates: mealRepository.availableDates
            )
            .disabled(isNavigating)
        }
        ToolbarItem(placement: .primaryAction) {
            WeekDatePickerToolbarButton(
                isPresented: $isSheetPresented,
                selectedDate: selectedDate,
                availableDates: mealRepository.availableDates,
                onSelect: applyDatePickerSelection
            )
            .disabled(isNavigating)
        }
    }

    private func applyDatePickerSelection(_ date: Date) {
        let newDate = Calendar.kst.startOfDay(for: date)
        scrollPositions[weekStart(for: newDate)] = newDate
        navigateTo(newDate)
    }
}

private struct WeekDatePickerToolbarButton: View {
    @Binding var isPresented: Bool
    let selectedDate: Date
    let availableDates: Set<Date>
    let onSelect: (Date) -> Void

    var body: some View {
        Button("날짜 선택", systemImage: "calendar") {
            isPresented.toggle()
        }
        #if os(macOS)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            WeekDatePickerModal(
                initialDate: selectedDate,
                availableDates: availableDates,
                onSelectedWeek: onSelect
            )
        }
        #endif
    }
}

/// iOS sheet 전용. macOS는 툴바 버튼 팝오버를 쓴다.
private struct WeekDatePickerPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let selectedDate: Date
    let availableDates: Set<Date>
    let onSelect: (Date) -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #else
        content.sheet(isPresented: $isPresented) {
            WeekDatePickerModal(
                initialDate: selectedDate,
                availableDates: availableDates,
                onSelectedWeek: onSelect
            )
        }
        #endif
    }
}

// MARK: - Navigation

private extension WeekMealScreen {
    /// 현재 주보다 이전 주 중 데이터가 있는 가장 가까운 날짜
    var nearestPrevDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealRepository.availableDates.filter { $0 < interval.start }.max()
    }

    /// 현재 주보다 이후 주 중 데이터가 있는 가장 가까운 날짜
    var nearestNextDate: Date? {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return nil }
        return mealRepository.availableDates.filter { $0 >= interval.end }.min()
    }

    /// 이전 pane에 표시할 날짜 (iOS 3-pane)
    var prevPaneDate: Date {
        if let t = transitionDate, t < selectedDate { return t }
        return nearestPrevDate ?? Calendar.kst.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
    }

    /// 다음 pane에 표시할 날짜 (iOS 3-pane)
    var nextPaneDate: Date {
        if let t = transitionDate, t > selectedDate { return t }
        return nearestNextDate ?? Calendar.kst.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
    }

    func commitNavigation(forward: Bool) {
        #if os(iOS)
        guard !isNavigating else { return }
        guard let targetDate = forward ? nearestNextDate : nearestPrevDate else {
            withAnimation(.spring) { dragOffset = 0 }
            return
        }
        isNavigating = true
        withAnimation(.spring(duration: 0.3, bounce: 0)) {
            dragOffset = forward ? -viewWidth : viewWidth
        }
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            await MainActor.run {
                let pending = pendingNavigation
                withTransaction(Transaction(animation: nil)) {
                    selectedDate = Calendar.kst.startOfDay(for: targetDate)
                    dragOffset = 0
                    isNavigating = false
                    pendingNavigation = nil
                }
                if let next = pending {
                    commitNavigation(forward: next)
                }
            }
        }
        #else
        guard let targetDate = forward ? nearestNextDate : nearestPrevDate else { return }
        navigateTo(Calendar.kst.startOfDay(for: targetDate))
        #endif
    }

    func navigateTo(_ newDate: Date) {
        guard !isNavigating else { return }
        let target = Calendar.kst.startOfDay(for: newDate)
        guard target != selectedDate else { return }

        #if os(iOS)
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
        #else
        isNavigating = true
        Task { @MainActor in
            let pending = pendingNavigation
            await ContentFadeTransition.run(opacity: $contentOpacity) {
                selectedDate = target
                pendingNavigation = nil
            }
            isNavigating = false
            if let next = pending {
                commitNavigation(forward: next)
            }
        }
        #endif
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
    @Previewable @State var mealRepository = MealRepository()
    let container = DayMealPreviewHelper.previewContainer(type: .normal)

    WeekMealScreen()
        .environment(mealRepository)
        .onAppear {
            do {
                try mealRepository.load(modelContext: ModelContext(container))
            } catch {
                print("Failed to load preview data: \(error)")
            }
        }
}
