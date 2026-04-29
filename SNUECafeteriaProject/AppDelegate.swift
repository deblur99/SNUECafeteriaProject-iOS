//
//  AppDelegate.swift
//  SNUECafeteriaProject
//
//  Created by 한현민 on 4/29/26.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
