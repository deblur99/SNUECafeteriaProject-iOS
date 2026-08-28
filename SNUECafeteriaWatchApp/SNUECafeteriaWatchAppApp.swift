//
//  SNUECafeteriaWatchAppApp.swift
//  SNUECafeteriaWatchApp
//

import SwiftUI

@main
struct SNUECafeteriaWatchAppApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    appDelegate.handleOpenURL(url)
                }
        }
    }
}
