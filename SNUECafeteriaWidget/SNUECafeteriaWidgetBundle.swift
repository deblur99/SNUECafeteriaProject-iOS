//
//  SNUECafeteriaWidgetBundle.swift
//  SNUECafeteriaWidget
//
//  Created by 한현민 on 5/18/26.
//

import WidgetKit
import SwiftUI

@main
struct SNUECafeteriaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SNUECafeteriaSmallWidget()
        SNUECafeteriaMediumWidget()
        SNUECafeteriaLargeWidget()
    }
}
