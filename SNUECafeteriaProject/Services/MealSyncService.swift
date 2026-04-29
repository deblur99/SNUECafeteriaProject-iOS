//
//  MealSyncService.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import FirebaseCore
import Foundation
import SwiftData

nonisolated enum MealSyncService {
    // MARK: - Public
    
    static func syncIfNeeded(modelContext: ModelContext) async {
        guard await shouldRefreshCache(modelContext: modelContext) else {
            print("No need to fetch from Firestore, using local cache")
            return
        }
        
        do {
            let meals = try await FirestoreService.shared.fetchAllMeals()
            print("meals.count: \(meals.count), meals.last: ")
            saveMealsToSwiftData(meals: meals, modelContext: modelContext)
        } catch {
            print("Error fetching meals: \(error)")
        }
    }
    
    // MARK: - SwiftData Transaction Helpers
    
    private static func loadMealsFromSwiftData(modelContext: ModelContext) async -> [DayMeal] {
        // 가져올 때 오래된 항목부터 큰 항목 순서대로 모든 항목 가져오기
        // - 나중에 커지면 일부만 가져오는 식으로 수정 가능
        let fetchRequest = FetchDescriptor<DayMeal>(
            sortBy: [.init(\.date, order: .forward)],
        )
        
        do {
            let cachedMeals = try modelContext.fetch(fetchRequest)
            return cachedMeals
        } catch {
            print("Error loading meals from SwiftData: \(error)")
            return []
        }
    }
    
    private static func loadLastMealFromSwiftData(modelContext: ModelContext) async -> DayMeal? {
        var fetchRequest = FetchDescriptor<DayMeal>(
            sortBy: [.init(\.date, order: .reverse)],
        )
        fetchRequest.fetchLimit = 1
        
        return try? modelContext.fetch(fetchRequest).last
    }
        
    private static func saveMealsToSwiftData(meals: [DayMeal], modelContext: ModelContext) {
        do {
            for meal in meals {
                modelContext.insert(meal)
            }
            try modelContext.save()
        } catch {
            print("Error saving meals to SwiftData: \(error)")
        }
    }
    
    // MARK: - Firestore Transactions Helpers
    
    private static func shouldRefreshCache(modelContext: ModelContext) async -> Bool {
        // 1. 로컬에 저장된 마지막 식단 확인
        guard let lastMeal = await loadLastMealFromSwiftData(modelContext: modelContext) else {
            print("캐시가 비어 있어 업데이트가 필요합니다.")
            return true
        }
        
        // 2. 마지막 저장일이 '오늘'인지 확인 (Calendar API 사용으로 월/년도 바뀜 문제 해결)
        let isUpToDate = Calendar.current.isDateInToday(lastMeal.createdAt)
        
        if isUpToDate {
            print("오늘 가져온 데이터가 있으므로 캐시를 유지합니다.")
            return false
        } else {
            print("캐시가 만료되어(어제 이전 데이터) 새로고침이 필요합니다.")
            return true
        }
    }
}
