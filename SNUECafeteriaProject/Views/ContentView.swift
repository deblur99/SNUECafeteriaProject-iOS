//
//  ContentView.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("오늘", systemImage: "sun.max") {
                TodayMealScreen()
            }

            Tab("주간", systemImage: "calendar") {
                WeekMealScreen()
            }

            Tab("설정", systemImage: "gear") {
                SettingsScreen()
            }
        }
    }
}

#Preview {
    ContentView()
}
