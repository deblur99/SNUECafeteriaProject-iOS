//
//  AppGroupsConfig.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/19/26.
//

import Foundation

nonisolated enum AppGroupsConfig {
    /// iOS/watchOS는 `group.` 접두, macOS는 Team ID 접두(샌드박스 App Group 규칙).
    static let groupIdentifier: String = {
        #if os(macOS)
        "44HRTG996V.com.deblurlab.SNUECafeteriaProject"
        #else
        "group.com.deblurlab.SNUECafeteriaProject"
        #endif
    }()
    
    nonisolated enum UserDefaultsKeys {
        static let cachedMeals = "cachedMeals"
        static let lastUpdated = "lastUpdated"
    }

    nonisolated enum NavigationKeys {
        static let pendingNavigationTab = "pendingNavigationTab"
    }
}
