//
//  SNUECafeteriaProjectApp.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/27/26.
//

import SwiftUI
import SwiftData

// TODO: 앱 화면 진입할 때마다 아래 작업 수행하기
// 1) 로컬 저장 확인: 로컬에 데이터가 있는지 확인하고, 없으면 Firebase로부터 데이터 가져오기 시도
// 2) 날짜 비교: 로컬에 저장된 데이터의 날짜와 오늘 날짜 비교 (한국 표준시 기준)해서, 날짜가 다르면 Firebase로부터 데이터 가져오기 시도

@main
struct SNUECafeteriaProjectApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DayMeal.self,
            MenuItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
