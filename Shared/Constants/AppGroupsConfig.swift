//
//  AppGroupsConfig.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/19/26.
//

import Foundation

nonisolated enum AppGroupsConfig {
    static let groupIdentifier = "group.com.deblurlab.SNUECafeteriaProject"
    
    nonisolated enum UserDefaultsKeys {
        static let cachedMeals = "cachedMeals"
        static let lastUpdated = "lastUpdated"
    }

    nonisolated enum NavigationKeys {
        static let pendingNavigationTab = "pendingNavigationTab"
    }
}
