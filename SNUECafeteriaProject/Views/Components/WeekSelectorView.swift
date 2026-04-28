//
//  WeekSelectorView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//

import SwiftUI

// TODO: 전체 데이터 가져와서 데이터가 없는 주는 선택 못하게 하기
struct WeekSelectorView: View {
    @Binding var selectedDateRange: ClosedRange<Date>
    
    private var dateRangeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일"
        let startString = dateFormatter.string(from: selectedDateRange.lowerBound)
        let endString = dateFormatter.string(from: selectedDateRange.upperBound)
        return "\(startString) ~ \(endString)"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                moveDateRangeToLastWeek()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.glass)
            
            Text(dateRangeString)
                .bold()
                .frame(minWidth: 160, alignment: .center)
            
            Button {
                moveDateRangeToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.glass)
        }
    }
    
    private func moveDateRangeToLastWeek() {
        selectedDateRange = Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: selectedDateRange.lowerBound
        )!...Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: selectedDateRange.upperBound
        )!
    }
    
    private func moveDateRangeToNextWeek() {
        selectedDateRange = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: selectedDateRange.lowerBound
        )!...Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: selectedDateRange.upperBound
        )!
    }
}

#Preview {
    @Previewable @State var selectedDateRange: ClosedRange<Date> = {
        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: endDate
        )!  // 끝 날짜에서 7일 전
        return startDate...endDate
    }()
    
    WeekSelectorView(selectedDateRange: $selectedDateRange)
}
