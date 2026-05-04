//
//  DayMealPreviewHelper.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/30/26.
//

import SwiftUI
import SwiftData

nonisolated enum DayMealPreviewHelper {
    nonisolated enum SampleType {
        case normal, empty, holiday
    }

    /// 프리뷰에서 쓸 테스트 데이터가 포함된 ModelContainer를 반환하는 메서드
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

/// 프리뷰에서 DayMeal 모델을 사용할 때, 미리보기 데이터를 주입하기 위한 ViewModifier
struct DayMealPreviewModifier: ViewModifier {
    let type: DayMealPreviewHelper.SampleType
    
    func body(content: Content) -> some View {
        content
            .environment(MealStore())
            .modelContainer(DayMealPreviewHelper.previewContainer(type: type))
    }
}
