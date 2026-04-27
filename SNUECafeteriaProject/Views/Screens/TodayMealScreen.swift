//
//  TodayMealScreen.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI

struct TodayMealScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    MealCardView()
                    
                    MealCardView()
                    
                    MealCardView()
                }
                .padding()
            }
            .navigationTitle("오늘의 식단")
        }
    }
}

#Preview {
    TodayMealScreen()
}
