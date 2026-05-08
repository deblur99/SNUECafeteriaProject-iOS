//
//  WeekMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct WeekMealScreen: View {
    @Environment(MealStore.self) private var mealStore
    
    private enum DragAxis {
        case horizontal, vertical
    }
    
    private enum TransitionDirection {
        case up, down, left, right
        
        var outgoingOffset: CGSize {
            switch self {
            case .up: CGSize(width: 0, height: -280)
            case .down: CGSize(width: 0, height: 280)
            case .left: CGSize(width: -120, height: 0)
            case .right: CGSize(width: 120, height: 0)
            }
        }
        
        var incomingStartOffset: CGSize {
            switch self {
            case .up: CGSize(width: 0, height: 120)
            case .down: CGSize(width: 0, height: -120)
            case .left: CGSize(width: 80, height: 0)
            case .right: CGSize(width: -80, height: 0)
            }
        }
    }
    
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
    
    private var selectedDay: Date {
        Calendar.kst.startOfDay(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
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
            .contentShape(Rectangle())
            .simultaneousGesture(dayWeekDragGesture)
            .background(Color(uiColor: .systemGroupedBackground))
            .onChange(of: selectedDate) { _, newDate in
                handleSelectedDateChange(newDate)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    
    private var dayWeekDragGesture: some Gesture {
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
                    if predicted <= -threshold {
                        moveDay(by: 1)
                    } else if predicted >= threshold {
                        moveDay(by: -1)
                    }
                case .horizontal:
                    let predicted = value.predictedEndTranslation.width
                    if predicted <= -threshold {
                        moveWeek(by: 1)
                    } else if predicted >= threshold {
                        moveWeek(by: -1)
                    }
                }
            }
    }
    
    private func moveDay(by days: Int) {
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
    
    private func moveWeek(by weeks: Int) {
        guard !isAnimatingPageTransition else { return }
        guard let targetDay = WeekNavigation.targetDateForWeekMove(
            from: selectedDay,
            weekOffset: weeks,
            availableDates: mealStore.availableDates
        ) else { return }
        
        pendingDirection = weeks > 0 ? .left : .right
        selectedDate = targetDay
    }
    
    @ViewBuilder
    private func dayContent(for date: Date) -> some View {
        let day = Calendar.kst.startOfDay(for: date)
        if let meal = mealStore.meal(for: day), meal.isHoliday || meal.hasLunch || meal.hasDinner {
            WeekDayMealView(meal: meal)
        } else {
            ContentUnavailableView(
                "식단 정보 없음",
                systemImage: "fork.knife",
                description: Text("해당 날짜의 식단 정보가 없습니다.")
            )
        }
    }
    
    private func handleSelectedDateChange(_ newDate: Date) {
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
    
    private func inferTransitionDirection(from current: Date, to target: Date) -> TransitionDirection {
        guard
            let currentInterval = Calendar.kstWeekInterval(for: current),
            let targetInterval = Calendar.kstWeekInterval(for: target)
        else { return target > current ? .up : .down }
        
        if targetInterval.start != currentInterval.start {
            return target > current ? .left : .right
        }
        return target > current ? .up : .down
    }
    
    private func animatePageTransition(to targetDate: Date, direction: TransitionDirection) {
        let animation = Animation.easeInOut(duration: 0.26)
        let duration: UInt64 = 260_000_000
        
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
