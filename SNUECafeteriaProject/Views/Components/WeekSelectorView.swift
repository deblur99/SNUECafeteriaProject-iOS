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
        weekHasData(weekOffset: -1)
    }
    
    private var canGoNext: Bool {
        weekHasData(weekOffset: 1)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                move(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.glass)
            .disabled(!canGoPrev)
            
            Text(dateRangeString)
                .bold()
                .frame(minWidth: 160, alignment: .center)
            
            Button {
                move(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.glass)
            .disabled(!canGoNext)
        }
    }
    
    private func move(by weeks: Int) {
        if let newDate = Calendar.kst.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    /// 지정한 주 오프셋의 주에 데이터가 하나라도 있는지 확인한다.
    private func weekHasData(weekOffset: Int) -> Bool {
        guard
            !availableDates.isEmpty,
            let targetDate = Calendar.kst.date(byAdding: .weekOfYear, value: weekOffset, to: selectedDate),
            let interval = Calendar.kstWeekInterval(for: targetDate)
        else { return false }
        return availableDates.contains { $0 >= interval.start && $0 < interval.end }
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = .now
    
    WeekSelectorView(selectedDate: $selectedDate, availableDates: [])
}
