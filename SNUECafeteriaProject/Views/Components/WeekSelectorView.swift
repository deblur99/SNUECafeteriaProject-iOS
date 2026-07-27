//
//  WeekSelectorView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI

// TODO: 전체 데이터 가져와서 데이터가 없는 주는 선택 못하게 하기
struct WeekSelectorView: View {
    @Binding var selectedDate: Date
    let availableDates: Set<Date>
    
    private var dateRangeString: String {
        guard let interval = Calendar.kstWeekInterval(for: selectedDate) else { return "" }
        // interval.end는 다음 주 월요일 00:00 (exclusive) → 1일 빼면 일요일
        let sunday = Calendar.kst.date(byAdding: .day, value: -1, to: interval.end)!
        return "\(DateFormatter.monthDay.string(from: interval.start)) ~ \(DateFormatter.monthDay.string(from: sunday))"
    }
    
    private var canGoPrev: Bool {
        WeekNavigation.weekHasData(
            selectedDate: selectedDate,
            weekOffset: -1,
            availableDates: availableDates
        )
    }
    
    private var canGoNext: Bool {
        WeekNavigation.weekHasData(
            selectedDate: selectedDate,
            weekOffset: 1,
            availableDates: availableDates
        )
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                move(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .glassCompatButtonStyle()
            .disabled(!canGoPrev)
            
            Text(dateRangeString)
                .bold()
                .frame(minWidth: 160, alignment: .center)
            
            Button {
                move(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .glassCompatButtonStyle()
            .disabled(!canGoNext)
        }
    }
    
    private func move(by weeks: Int) {
        if let newDate = WeekNavigation.targetDateForWeekMove(
            from: selectedDate,
            weekOffset: weeks,
            availableDates: availableDates
        ) {
            selectedDate = newDate
        }
    }
}

enum WeekNavigation {
    /// 지정한 주 오프셋의 주에 데이터가 하나라도 있는지 확인한다.
    static func weekHasData(selectedDate: Date, weekOffset: Int, availableDates: Set<Date>) -> Bool {
        guard
            !availableDates.isEmpty,
            let targetDate = Calendar.kst.date(byAdding: .weekOfYear, value: weekOffset, to: selectedDate),
            let interval = Calendar.kstWeekInterval(for: targetDate)
        else { return false }
        
        return availableDates.contains { $0 >= interval.start && $0 < interval.end }
    }
    
    /// 주 이동 시 선택할 날짜를 반환한다.
    /// - 우선순위: 동일 요일 > 해당 주의 가장 빠른 날짜
    static func targetDateForWeekMove(from selectedDate: Date, weekOffset: Int, availableDates: Set<Date>) -> Date? {
        guard
            weekHasData(selectedDate: selectedDate, weekOffset: weekOffset, availableDates: availableDates),
            let shiftedDate = Calendar.kst.date(byAdding: .weekOfYear, value: weekOffset, to: selectedDate),
            let interval = Calendar.kstWeekInterval(for: shiftedDate)
        else { return nil }
        
        let preferredDay = Calendar.kst.startOfDay(for: shiftedDate)
        let candidates = availableDates
            .filter { $0 >= interval.start && $0 < interval.end }
            .sorted()
        
        if candidates.contains(preferredDay) {
            return preferredDay
        }
        
        let preferredWeekday = Calendar.kst.component(.weekday, from: preferredDay)
        if let sameWeekday = candidates.first(where: { Calendar.kst.component(.weekday, from: $0) == preferredWeekday }) {
            return sameWeekday
        }
        
        return candidates.first
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = .now
    
    WeekSelectorView(selectedDate: $selectedDate, availableDates: [])
}
