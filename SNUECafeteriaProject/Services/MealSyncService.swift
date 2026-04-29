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
    
    static func syncIfNeeded(modelContext: ModelContext) async -> [DayMeal] {
        guard await checkFetchFromFirestoreNeeded(modelContext: modelContext) else {
            print("No need to fetch from Firestore, using local cache")
            return await loadMealsFromSwiftData(modelContext: modelContext)
        }
        
        do {
            let meals = try await FirestoreManager.shared.fetchAllMeals()
            print("meals.count: \(meals.count), meals.last: ")
            saveMealsToSwiftData(meals: meals, modelContext: modelContext)
            return meals
        } catch {
            print("Error fetching meals: \(error)")
            return []
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
    
    private static func checkFetchFromFirestoreNeeded(modelContext: ModelContext) async -> Bool {
        // 로컬에서 가져온 걸로 확인해서 로컬에 저장된 날짜가 오늘 날짜보다 앞이면 Firestore에서 가져와야 함
        guard let lastMeal = await loadLastMealFromSwiftData(modelContext: modelContext) else {
            print("No meals in local cache, fetch from Firestore needed")
            return true
        }
        
        let nowAsDay = Calendar.current.component(.day, from: .now)
        let lastMealCreatedAtAsDay = Calendar.current.component(.day, from: lastMeal.createdAt)
        
        if nowAsDay - lastMealCreatedAtAsDay > 0 {
            // 하루 이상 지났으면 서버에서 가져오도록 함
            print("Fetch from Firestore needed: last meal created at \(lastMeal.createdAt), now is \(Date())")
            return true
        } else {
            // 당일 가져온 데이터면 그대로 사용하도록 함
            print("Fetch from Firestore NOT needed: last meal created at \(lastMeal.createdAt), now is \(Date())")
            return false
        }
    }
}
