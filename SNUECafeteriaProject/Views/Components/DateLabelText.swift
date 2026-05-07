//
//  DateLabelText.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/7/26.
//

import SwiftUI

struct DateLabelText: View {
    let date: Date
    
    var body: some View {
        Text(String.shortDateLabel(from: date))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    DateLabelText(date: .now)
}
