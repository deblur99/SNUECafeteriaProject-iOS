//
//  DayMealPreviewHelper.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/30/26.
//

import Foundation
import SwiftData

nonisolated enum DayMealPreviewHelper {
    nonisolated enum SampleType {
        case normal, empty, holiday
    }

    static func previewContainer(type: SampleType) -> ModelContainer {
        let container = try! ModelContainer(
            for: DayMeal.self,
            configurations: .init(
                isStoredInMemoryOnly: true,
            )
        )
        let context = ModelContext(container)
        let data = switch type {
        case .normal:
            DayMeal.sample()
        case .empty:
            DayMeal.sampleEmpty()
        case .holiday:
            DayMeal.sampleHoliday()
        }
        context.insert(data)
        try! context.save() // 컨텍스트가 컨테이너에 데이터 저장
        return container // 저장된 데이터가 있는 컨테이너 인스턴스 반환
    }
}


