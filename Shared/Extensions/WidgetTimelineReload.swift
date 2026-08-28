//
//  WidgetTimelineReload.swift
//  Shared
//

import WidgetKit

enum WidgetTimelineReload {
    static func requestAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
