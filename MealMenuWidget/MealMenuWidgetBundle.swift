//
//  MealMenuWidgetBundle.swift
//  MealMenuWidget
//
//  Created by 한현민 on 5/15/26.
//

import WidgetKit
import SwiftUI

@main
struct MealMenuWidgetBundle: WidgetBundle {
    var body: some Widget {
        MealMenuWidget()
        MealMenuWidgetControl()
        MealMenuWidgetLiveActivity()
    }
}
