//
//  WeekDatePickerModal.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/28/26.
//


import SwiftUI

struct WeekDatePickerModal: View {
    var onSelected: (Date) -> ()
    
    @State private var selectedDate: Date = .now
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DatePicker(
                "확인할 주 선택",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationTitle("확인할 주 선택")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        onSelected(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}