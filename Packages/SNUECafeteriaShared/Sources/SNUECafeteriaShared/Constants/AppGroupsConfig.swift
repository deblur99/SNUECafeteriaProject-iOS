//
//  AppGroupsConfig.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 5/19/26.
//

import Foundation

public nonisolated enum AppGroupsConfig {
    public static let groupIdentifier = "group.com.deblurlab.SNUECafeteriaProject"
    
    public nonisolated enum UserDefaultsKeys {
        public static let cachedMeals = "cachedMeals"
        public static let lastUpdated = "lastUpdated"
    }

    public nonisolated enum NavigationKeys {
        public static let pendingNavigationTab = "pendingNavigationTab"
    }
}
