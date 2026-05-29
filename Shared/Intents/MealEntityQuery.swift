//
//  MealEntityQuery.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/29/26.
//

import AppIntents
import Foundation

nonisolated struct MealEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MealEntity] {
        let idSet = Set(identifiers)
        return AppGroupMealCache.load()
            .filter { idSet.contains(DateFormatter.kstDash.string(from: $0.date)) }
            .map(MealEntity.init)
    }

    func suggestedEntities() async throws -> [MealEntity] {
        let today = Calendar.kst.startOfDay(for: .now)
        return AppGroupMealCache.load()
            .filter { Calendar.kst.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
            .map(MealEntity.init)
    }

    func defaultResult() async -> MealEntity? {
        AppGroupMealCache.load()
            .first { Calendar.kst.isDateInToday($0.date) }
            .map(MealEntity.init)
    }
}

extension MealEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [MealEntity] {
        AppGroupMealCache.load()
            .map(MealEntity.init)
            .filter { DateFormatter.longDateLabel.string(from: $0.date).contains(string) }
    }
}
