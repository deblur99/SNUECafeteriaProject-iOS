//
//  MealShareFormatter.swift
//  Shared
//

import Foundation
import KSTDateKit

nonisolated enum MealShareFormatter {
    static func text(for meal: CachedDayMeal) -> String {
        var lines = headerLines(for: meal.date)

        if meal.isHoliday {
            lines.append("휴무일")
            return joinedLines(lines)
        }

        appendMealSection(title: MealType.lunch.label, items: meal.sortedLunchItems.map(\.name), to: &lines)
        appendMealSection(title: MealType.dinner.label, items: meal.sortedDinnerItems.map(\.name), to: &lines)

        return joinedLines(lines)
    }

    static func text(for meal: CachedDayMeal, mealType: MealType) -> String {
        var lines = headerLines(for: meal.date)
        let items = mealType == .lunch
            ? meal.sortedLunchItems.map(\.name)
            : meal.sortedDinnerItems.map(\.name)
        appendMealSection(title: mealType.label, items: items, to: &lines)
        return joinedLines(lines)
    }

    static func filename(for date: Date, fileExtension: String) -> String {
        "SNUECafeteria_Menu_\(DateFormatter.kstCompact.string(from: date)).\(fileExtension)"
    }

    private static func headerLines(for date: Date) -> [String] {
        [
            "서울교대 학식 메뉴",
            DateFormatter.longDateLabel.string(from: date),
            "",
        ]
    }

    private static func appendMealSection(title: String, items: [String], to lines: inout [String]) {
        lines.append("[\(title)]")
        if items.isEmpty {
            lines.append("식단 없음")
        } else {
            lines.append(contentsOf: items)
        }
        lines.append("")
    }

    private static func trimmed(_ lines: [String]) -> [String] {
        var result = lines
        while result.last?.isEmpty == true {
            result.removeLast()
        }
        return result
    }

    private static func joinedLines(_ lines: [String]) -> String {
        trimmed(lines)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
