//
//  View+Conditional.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/6/26.
//

import SwiftUI

extension View {
    /// 조건이 true일 때만 주어진 transform을 적용합니다.
    /// false일 때는 modifier 자체를 적용하지 않으므로, clipsToBounds 등 부수효과도 발생하지 않습니다.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
