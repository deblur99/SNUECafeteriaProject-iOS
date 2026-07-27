//
//  SNUECafeteriaProjectWatchAppApp.swift
//  SNUECafeteriaProjectWatchApp Watch App
//
//  Created by 한현민 on 6/8/26.
//

import SwiftUI

@main
struct SNUECafeteriaProjectWatchApp_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
