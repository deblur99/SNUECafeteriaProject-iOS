//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

// MARK: - Supporting Types

fileprivate enum DragAxis {
    case horizontal, vertical
}

fileprivate enum TransitionDirection {
    case up, down, left, right

    var outgoingOffset: CGSize {
        switch self {
        case .up:    CGSize(width: 0, height: -280)
        case .down:  CGSize(width: 0, height:  280)
        case .left:  CGSize(width: -260, height: 0)
        case .right: CGSize(width:  260, height: 0)
        }
    }

    var incomingStartOffset: CGSize {
        switch self {
        case .up:    CGSize(width: 0, height:  120)
        case .down:  CGSize(width: 0, height: -120)
        case .left:  CGSize(width:  220, height: 0)
        case .right: CGSize(width: -220, height: 0)
        }
    }

    var transitionAnimation: Animation {
        switch self {
        case .left, .right:
            return .interactiveSpring(response: 0.42, dampingFraction: 0.9, blendDuration: 0.12)
        case .up, .down:
            return .easeInOut(duration: 0.3)
        }
    }

    var transitionDuration: UInt64 {
        switch self {
        case .left, .right: return 420_000_000
        case .up, .down:    return 300_000_000
        }
    }
}

fileprivate enum DayNavSummary {
    case holiday, hasBoth, lunchOnly, dinnerOnly, empty, noData

    var label: String {
        switch self {
        case .holiday:   "휴무"
        case .hasBoth:   "중식 · 석식"
        case .lunchOnly: "중식만"
        case .dinnerOnly:"석식만"
        case .empty:     "식단 없음"
        case .noData:    "정보 없음"
        }
    }
}

// MARK: - WeekMealScreen

struct WeekMealScreen: View {
    @Environment(MealStore.self) private var mealStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: State

    @State private var selectedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var isSheetPresented: Bool = false
    @State private var dragAxis: DragAxis?
    @State private var displayedDate: Date = Calendar.kst.startOfDay(for: Date())
    @State private var incomingDate: Date?
    @State private var currentOffset: CGSize = .zero
    @State private var incomingOffset: CGSize = .zero
    @State private var currentOpacity: Double = 1
    @State private var incomingOpacity: Double = 0
    @State private var isAnimatingPageTransition = false
    @State private var pendingDirection: TransitionDirection?

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    multiDayContent
                } else {
                    singleDayContent
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .onChange(of: selectedDate) { _, newDate in
                handleSelectedDateChange(newDate)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if horizontalSizeClass == .regular {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: 2) {
                            Button("이전 주", systemImage: "chevron.left") { moveWeek(by: -1) }
                            Button("다음 주", systemImage: "chevron.right") { moveWeek(by: 1) }
                        }
                    }
                }
                ToolbarItem(placement: .title) {
                    WeekSelectorView(
                        selectedDate: $selectedDate,
                        availableDates: mealStore.availableDates
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("날짜 선택", systemImage: "calendar") {
                        isSheetPresented.toggle()
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                WeekDatePickerModal(
                    initialDate: selectedDate,
                    availableDates: mealStore.availableDates
                ) { date in
                    let target = Calendar.kst.startOfDay(for: date)
                    pendingDirection = inferTransitionDirection(from: selectedDay, to: target)
                    selectedDate = target
                }
            }
        }
    }
}

// MARK: - Navigation Metadata

private extension WeekMealScreen {
    var selectedDay: Date {
        Calendar.kst.startOfDay(for: selectedDate)
    }

    var prevDayInWeek: Date? {
        Calendar.kst.date(byAdding: .day, value: -1, to: selectedDay)
            .flatMap { date -> Date? in
                guard let interval = Calendar.kstWeekInterval(for: selectedDay) else { return nil }
                let d = Calendar.kst.startOfDay(for: date)
                return d >= interval.start && d < interval.end ? d : nil
            }
    }

    var nextDayInWeek: Date? {
        Calendar.kst.date(byAdding: .day, value: 1, to: selectedDay)
            .flatMap { date -> Date? in
                guard let interval = Calendar.kstWeekInterval(for: selectedDay) else { return nil }
                let d = Calendar.kst.startOfDay(for: date)
                return d >= interval.start && d < interval.end ? d : nil
            }
    }

    var canMoveToPrevDay: Bool {
        guard let d = prevDayInWeek else { return false }
        return mealStore.availableDates.contains(d)
    }

    var canMoveToNextDay: Bool {
        guard let d = nextDayInWeek else { return false }
        return mealStore.availableDates.contains(d)
    }

    var weekDays: [Date] {
        guard let interval = Calendar.kstWeekInterval(for: selectedDay) else { return [] }
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            guard let next = Calendar.kst.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }
}

// MARK: - Layout

private extension WeekMealScreen {
    var singleDayContent: some View {
        ZStack {
            if let incomingDate {
                dayContent(for: incomingDate)
                    .offset(incomingOffset)
                    .opacity(incomingOpacity)
                    .zIndex(0)
            }

            dayContent(for: displayedDate)
                .offset(currentOffset)
                .opacity(currentOpacity)
                .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay(alignment: .top) {
            if let prev = prevDayInWeek {
                Button {
                    moveDay(by: -1)
                } label: {
                    swipeHintView(for: prev, isTop: true, isEnabled: canMoveToPrevDay)
                        .padding(.top, 12)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let next = nextDayInWeek {
                Button {
                    moveDay(by: 1)
                } label: {
                    swipeHintView(for: next, isTop: false, isEnabled: canMoveToNextDay)
                        .padding(.bottom, 12)
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(dayWeekDragGesture)
    }

    var multiDayContent: some View {
        GeometryReader { geometry in
            let cols = geometry.size.width >= 900 ? 3 : 2
            let colWidth = geometry.size.width / CGFloat(cols)
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(weekDays, id: \.self) { date in
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(date == selectedDay ? Color.accentColor : Color.clear)
                                    .frame(height: 3)
                                dayContent(for: date)
                            }
                            .frame(width: colWidth, height: geometry.size.height)
                            .overlay(alignment: .trailing) {
                                Rectangle()
                                    .fill(Color(uiColor: .separator))
                                    .frame(width: 0.5)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedDate = date }
                            .id(date)
                        }
                    }
                }
                .onAppear {
                    scrollProxy.scrollTo(selectedDay, anchor: .leading)
                }
                .onChange(of: selectedDay) { _, newDay in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo(newDay, anchor: .leading)
                    }
                }
            }
        }
    }
}

// MARK: - Gesture Handling

private extension WeekMealScreen {
    var dayWeekDragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard dragAxis == nil, !isAnimatingPageTransition else { return }

                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                guard max(horizontal, vertical) > 12 else { return }

                dragAxis = horizontal > vertical ? .horizontal : .vertical
            }
            .onEnded { value in
                defer { dragAxis = nil }
                guard let dragAxis else { return }

                let threshold: CGFloat = 80
                switch dragAxis {
                case .vertical:
                    let predicted = value.predictedEndTranslation.height
                    if predicted <= -threshold { moveDay(by: 1) }
                    else if predicted >= threshold { moveDay(by: -1) }
                case .horizontal:
                    let predicted = value.predictedEndTranslation.width
                    if predicted <= -threshold { moveWeek(by: 1) }
                    else if predicted >= threshold { moveWeek(by: -1) }
                }
            }
    }

    func moveDay(by days: Int) {
        guard !isAnimatingPageTransition else { return }
        guard
            let target = Calendar.kst.date(byAdding: .day, value: days, to: selectedDay),
            let weekInterval = Calendar.kstWeekInterval(for: selectedDay)
        else { return }

        let targetDay = Calendar.kst.startOfDay(for: target)
        guard
            targetDay >= weekInterval.start,
            targetDay < weekInterval.end,
            mealStore.availableDates.contains(targetDay)
        else { return }

        pendingDirection = days > 0 ? .up : .down
        selectedDate = targetDay
    }

    func moveWeek(by weeks: Int) {
        guard !isAnimatingPageTransition else { return }
        guard let targetDay = WeekNavigation.targetDateForWeekMove(
            from: selectedDay,
            weekOffset: weeks,
            availableDates: mealStore.availableDates
        ) else { return }

        pendingDirection = weeks > 0 ? .left : .right
        selectedDate = targetDay
    }
}

// MARK: - Transition Animation

private extension WeekMealScreen {
    func handleSelectedDateChange(_ newDate: Date) {
        let normalizedDate = Calendar.kst.startOfDay(for: newDate)
        if normalizedDate != newDate {
            selectedDate = normalizedDate
            return
        }

        guard normalizedDate != displayedDate else { return }
        guard !isAnimatingPageTransition else { return }

        let direction = pendingDirection ?? inferTransitionDirection(from: displayedDate, to: normalizedDate)
        pendingDirection = nil
        animatePageTransition(to: normalizedDate, direction: direction)
    }

    func inferTransitionDirection(from current: Date, to target: Date) -> TransitionDirection {
        guard
            let currentInterval = Calendar.kstWeekInterval(for: current),
            let targetInterval = Calendar.kstWeekInterval(for: target)
        else { return target > current ? .up : .down }

        if targetInterval.start != currentInterval.start {
            return target > current ? .left : .right
        }
        return target > current ? .up : .down
    }

    func animatePageTransition(to targetDate: Date, direction: TransitionDirection) {
        let animation = direction.transitionAnimation
        let duration = direction.transitionDuration

        isAnimatingPageTransition = true
        incomingDate = targetDate
        currentOffset = .zero
        currentOpacity = 1
        incomingOffset = direction.incomingStartOffset
        incomingOpacity = 0

        withAnimation(animation) {
            currentOffset = direction.outgoingOffset
            currentOpacity = 0
            incomingOffset = .zero
            incomingOpacity = 1
        }

        Task {
            try? await Task.sleep(nanoseconds: duration)
            await MainActor.run {
                displayedDate = targetDate
                incomingDate = nil
                currentOffset = .zero
                currentOpacity = 1
                incomingOffset = .zero
                incomingOpacity = 0
                isAnimatingPageTransition = false
            }
        }
    }
}

// MARK: - Swipe Hint Views

private extension WeekMealScreen {
    func navSummary(for date: Date) -> DayNavSummary {
        guard let meal = mealStore.meal(for: date) else { return .noData }
        if meal.isHoliday { return .holiday }
        switch (meal.hasLunch, meal.hasDinner) {
        case (true,  true):  return .hasBoth
        case (true,  false): return .lunchOnly
        case (false, true):  return .dinnerOnly
        case (false, false): return .empty
        }
    }

    @ViewBuilder
    func swipeHintView(for date: Date, isTop: Bool, isEnabled: Bool) -> some View {
        let summary = navSummary(for: date)
        let dateLabel = DateFormatter.shortDateLabel.string(from: date)
        HStack(spacing: 6) {
            Image(systemName: isTop ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
            Text("\(dateLabel) · \(summary.label)")
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(isEnabled ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .allowsHitTesting(false)
    }
}

// MARK: - Day Content

private extension WeekMealScreen {
    @ViewBuilder
    func dayContent(for date: Date) -> some View {
        let day = Calendar.kst.startOfDay(for: date)
        if let meal = mealStore.meal(for: day) {
            WeekDayMealView(meal: meal)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DateLabelText(date: day)
                        .padding(.horizontal, 4)
                    ContentUnavailableView(
                        "식단 정보 없음",
                        systemImage: "fork.knife",
                        description: Text("해당 날짜의 식단 정보가 없습니다.")
                    )
                }
                .padding(.top, 16)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

// MARK: - WeekDayMealView

private struct WeekDayMealView: View {
    let meal: DayMeal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DateLabelText(date: meal.date)
                    .padding(.horizontal, 4)

                DayMealCardsView(dayMeal: meal)
            }
            .padding(.top, 16)
            .padding(.horizontal)
            .padding(.bottom)
        }
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
