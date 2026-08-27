import ProjectDescription

private let bundleID = "com.deblurlab.SNUECafeteriaProject"
private let teamID = "44HRTG996V"

let project = Project(
    name: "SNUECafeteriaProject",
    organizationName: "deblurlab",
    options: .options(
        automaticSchemesOptions: .enabled(),
        defaultKnownRegions: ["en", "Base"],
        developmentRegion: "en"
    ),
    packages: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.12.1"),
        .package(url: "https://github.com/deblur99/WatchConnectivityKit", from: "1.0.1"),
    ],
    settings: .settings(
        base: [
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "DEVELOPMENT_TEAM": .string(teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "MARKETING_VERSION": "1.0",
            "CURRENT_PROJECT_VERSION": "1",
        ]
    ),
    targets: [
        .target(
            name: "SNUECafeteriaProject",
            destinations: .iOS,
            product: .app,
            bundleId: bundleID,
            deploymentTargets: .iOS("26.0"),
            infoPlist: .file(path: "SNUECafeteriaProjectiOS/Info.plist"),
            sources: [
                "SNUECafeteriaProjectiOS/**/*.swift",
                "SNUECafeteriaProject/**/*.swift",
                "Shared/**/*.swift",
            ],
            resources: [
                "SNUECafeteriaProjectiOS/Assets.xcassets",
                "Shared/AppIcon.icon",
                "SNUECafeteriaProjectiOS/GoogleService-Info.plist",
            ],
            entitlements: "SNUECafeteriaProjectiOS/SNUECafeteriaProject.entitlements",
            dependencies: [
                .target(name: "SNUECafeteriaWidgetExtension"),
                .target(name: "SNUECafeteriaWatchApp"),
                .package(product: "WatchConnectivityKit"),
                .package(product: "FirebaseAnalytics"),
                .package(product: "FirebaseCore"),
                .package(product: "FirebaseCrashlytics"),
                .package(product: "FirebaseFirestore"),
                .package(product: "FirebaseFunctions"),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ENABLE_PREVIEWS": "YES",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_KEY_CFBundleDisplayName": "교대학식",
                "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.lifestyle",
                "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
                "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
                "INFOPLIST_KEY_UILaunchStoryboardName": "",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                "OTHER_LDFLAGS": "-ObjC",
                "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "6.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            ])
        ),
        .target(
            name: "SNUECafeteriaWatchApp",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "\(bundleID).watchkitapp",
            deploymentTargets: .watchOS("11.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "교대학식",
                "WKCompanionAppBundleIdentifier": .string(bundleID),
            ]),
            sources: [
                "SNUECafeteriaWatchApp/**/*.swift",
                "Shared/Cache/**/*.swift",
                "Shared/Constants/**/*.swift",
                "Shared/Extensions/**/*.swift",
                "Shared/Models/**/*.swift",
                "Shared/WatchConnectivity/**/*.swift",
                "SNUECafeteriaProject/Services/NetworkService.swift",
            ],
            resources: [
                "SNUECafeteriaWatchApp/Assets.xcassets",
                "Shared/AppIcon.icon",
                "SNUECafeteriaProjectiOS/GoogleService-Info.plist",
            ],
            entitlements: "SNUECafeteriaWatchApp/SNUECafeteriaWatchApp.entitlements",
            dependencies: [
                .package(product: "WatchConnectivityKit"),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ENABLE_DEBUG_DYLIB": "NO",
                "ENABLE_PREVIEWS": "YES",
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_KEY_CFBundleDisplayName": "교대학식",
                "INFOPLIST_KEY_CFBundleIconName": "AppIcon",
                "INFOPLIST_KEY_WKCompanionAppBundleIdentifier": .string(bundleID),
                "PRODUCT_NAME": "SNUECafeteriaWatch",
                "SKIP_INSTALL": "YES",
                "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "6.0",
                "TARGETED_DEVICE_FAMILY": "4",
            ])
        ),
        .target(
            name: "SNUECafeteriaWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(bundleID).SNUECafeteriaWidget",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "SNUECafeteriaWidget",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: [
                .glob(
                    "SNUECafeteriaWidget/**/*.swift"
                ),
                .glob(
                    "Shared/**/*.swift",
                    excluding: ["Shared/WatchConnectivity/**"]
                ),
            ],
            resources: [
                "SNUECafeteriaWidget/Assets.xcassets",
            ],
            entitlements: "SNUECafeteriaWidgetExtension.entitlements",
            dependencies: [
                .sdk(name: "WidgetKit", type: .framework),
                .sdk(name: "SwiftUI", type: .framework),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME": "WidgetBackground",
                "SKIP_INSTALL": "YES",
                "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            ])
        ),
        .target(
            name: "SNUECafeteriaMac",
            destinations: [.mac],
            product: .app,
            bundleId: "\(bundleID).mac",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "교대학식",
                "CFBundleName": "교대학식",
                "LSApplicationCategoryType": "public.app-category.lifestyle",
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLName": "com.deblurlab.SNUECafeteriaProject.mac",
                        "CFBundleURLSchemes": ["snuecafeteria"],
                    ],
                ],
            ]),
            sources: [
                "SNUECafeteriaMac/**/*.swift",
                .glob(
                    "Shared/**/*.swift",
                    excluding: ["Shared/WatchConnectivity/**"]
                ),
                "SNUECafeteriaProject/**/*.swift",
            ],
            resources: [
                "SNUECafeteriaMac/Assets.xcassets",
                "Shared/AppIcon.icon",
                "SNUECafeteriaMac/GoogleService-Info.plist",
            ],
            entitlements: "SNUECafeteriaMac/SNUECafeteriaMac.entitlements",
            dependencies: [
                .target(name: "SNUECafeteriaMacWidgetExtension"),
                .package(product: "FirebaseCore"),
                .package(product: "FirebaseFirestore"),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                // macOS Automatic 서명: 기본 "-"만 두면 Xcode UI의 Certificate가 비거나 Sign to Run Locally로 풀림
                "CODE_SIGN_IDENTITY": "-",
                "CODE_SIGN_IDENTITY[sdk=macosx*]": "Apple Development",
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": .string(teamID),
                "ENABLE_PREVIEWS": "YES",
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_KEY_CFBundleDisplayName": "교대학식",
                "INFOPLIST_KEY_CFBundleName": "교대학식",
                "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.lifestyle",
                "MACOSX_DEPLOYMENT_TARGET": "26.0",
                // PRODUCT_NAME에 한글을 쓰면 APFS NFD/NFC 정규화로 CodeSign이
                // Contents/MacOS/<이름>을 못 찾아 실패한다. 표시명은 CFBundle*로만 둔다.
                "PRODUCT_NAME": "SNUECafeteriaMac",
                "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "6.0",
            ])
        ),
        .target(
            name: "SNUECafeteriaMacWidgetExtension",
            destinations: [.mac],
            product: .extensionKitExtension,
            bundleId: "\(bundleID).mac.widget",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "교대학식",
                "CFBundleName": "교대학식",
                "EXAppExtensionAttributes": [
                    "EXExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: [
                .glob("SNUECafeteriaWidget/**/*.swift"),
                .glob("Shared/Cache/**/*.swift"),
                .glob("Shared/Constants/**/*.swift"),
                .glob("Shared/Models/**/*.swift"),
                .glob(
                    "Shared/Extensions/**/*.swift",
                    excluding: [
                        "Shared/Extensions/View+PlatformChrome.swift",
                        "Shared/Extensions/MealPeriodTransition.swift",
                        "Shared/Extensions/Color+GroupedBackground.swift",
                    ]
                ),
            ],
            resources: [
                "SNUECafeteriaWidget/Assets.xcassets",
            ],
            entitlements: "SNUECafeteriaMacWidgetExtension.entitlements",
            dependencies: [
                .sdk(name: "WidgetKit", type: .framework),
                .sdk(name: "SwiftUI", type: .framework),
            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME": "WidgetBackground",
                "CODE_SIGN_IDENTITY": "-",
                "CODE_SIGN_IDENTITY[sdk=macosx*]": "Apple Development",
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": .string(teamID),
                "GENERATE_INFOPLIST_FILE": "YES",
                "INFOPLIST_KEY_CFBundleDisplayName": "교대학식",
                "INFOPLIST_KEY_CFBundleName": "교대학식",
                "MACOSX_DEPLOYMENT_TARGET": "26.0",
                "PRODUCT_NAME": "SNUECafeteriaMacWidgetExtension",
                "SKIP_INSTALL": "YES",
                "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "5.0",
            ])
        ),
        .target(
            name: "SNUECafeteriaProjectTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleID)Tests",
            deploymentTargets: .iOS("26.4"),
            infoPlist: .default,
            sources: ["SNUECafeteriaProjectTests/**/*.swift"],
            dependencies: [
                .target(name: "SNUECafeteriaProject"),
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "STRING_CATALOG_GENERATE_SYMBOLS": "NO",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_EMIT_LOC_STRINGS": "NO",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            ])
        ),
        .target(
            name: "SNUECafeteriaProjectUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(bundleID)UITests",
            infoPlist: .default,
            sources: ["SNUECafeteriaProjectUITests/**/*.swift"],
            dependencies: [
                .target(name: "SNUECafeteriaProject"),
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "STRING_CATALOG_GENERATE_SYMBOLS": "NO",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_EMIT_LOC_STRINGS": "NO",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            ])
        ),
    ],
    schemes: [
        .scheme(
            name: "SNUECafeteriaProject",
            shared: true,
            buildAction: .buildAction(targets: ["SNUECafeteriaProject"]),
            testAction: .targets(["SNUECafeteriaProjectTests", "SNUECafeteriaProjectUITests"]),
            runAction: .runAction(executable: "SNUECafeteriaProject"),
            archiveAction: .archiveAction(configuration: .release)
        ),
        .scheme(
            name: "SNUECafeteriaWatchApp",
            shared: true,
            buildAction: .buildAction(targets: ["SNUECafeteriaWatchApp"]),
            runAction: .runAction(executable: "SNUECafeteriaWatchApp")
        ),
        .scheme(
            name: "SNUECafeteriaMac",
            shared: true,
            buildAction: .buildAction(targets: ["SNUECafeteriaMac", "SNUECafeteriaMacWidgetExtension"]),
            runAction: .runAction(executable: "SNUECafeteriaMac")
        ),
    ]
)
