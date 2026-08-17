import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")

// CryptoCoreKit is no longer a Tuist target built from source — it's an
// external, closed-source SDK package (see ../CryptoCoreKitSDK) built from
// ../SDKBuild and referenced here as a binary dependency via
// Tuist/Package.swift. Feature modules depend on it exactly the same way
// they'd depend on any third-party SPM package.

let navigationKit = Target.target(
    name: "NavigationKit",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.navigationkit",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/NavigationKit/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit")
    ]
)

let designSystemKit = Target.target(
    name: "DesignSystemKit",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.designsystemkit",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/DesignSystemKit/Sources/**"]
)

let marketsFeature = Target.target(
    name: "MarketsFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.marketsfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/MarketsFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit"),
        .external(name: "ComposableArchitecture"),
        .target(name: "DesignSystemKit"),
    ]
)

let newsFeature = Target.target(
    name: "NewsFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.newsfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/NewsFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit"),
        .external(name: "ComposableArchitecture"),
        .target(name: "DesignSystemKit"),
    ]
)

let watchlistFeature = Target.target(
    name: "WatchlistFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.watchlistfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/WatchlistFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit"),
        .external(name: "ComposableArchitecture"),
        .target(name: "DesignSystemKit"),
    ]
)

let asyncFeature = Target.target(
    name: "AsyncFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.asyncfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/AsyncFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit"),
        .external(name: "ComposableArchitecture"),
        .target(name: "DesignSystemKit"),
    ]
)

let grpcFeature = Target.target(
    name: "GrpcFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.grpcfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/GrpcFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit"),
        .external(name: "ElizaProtoKit"),
        .external(name: "ComposableArchitecture"),
        .target(name: "DesignSystemKit"),
    ]
)

let app = Target.target(
    name: "CryptoCoreApp",
    destinations: .iOS,
    product: .app,
    bundleId: "com.example.cryptocoreapp",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [
            "UIColorName": "",
            "UIImageRespectsSafeAreaInsets": false,
        ],
    ]),
    sources: ["Sources/**"],
    dependencies: [
        .target(name: "MarketsFeature"),
        .target(name: "NewsFeature"),
        .target(name: "WatchlistFeature"),
        .target(name: "AsyncFeature"),
        .target(name: "GrpcFeature"),
        .target(name: "NavigationKit"),
        .target(name: "DesignSystemKit"),
        .external(name: "ComposableArchitecture"),
    ]
)

let project = Project(
    name: "CryptoCoreApp",
    targets: [app, navigationKit, designSystemKit, marketsFeature, newsFeature, watchlistFeature, asyncFeature, grpcFeature]
)
