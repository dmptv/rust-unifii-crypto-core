import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")

// CryptoCoreKit is no longer a Tuist target built from source — it's an
// external, closed-source SDK package (see ../CryptoCoreKitSDK) built from
// ../SDKBuild and referenced here as a binary dependency via
// Tuist/Package.swift. Feature modules depend on it exactly the same way
// they'd depend on any third-party SPM package.

let marketsFeature = Target.target(
    name: "MarketsFeature",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.marketsfeature",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/MarketsFeature/Sources/**"],
    dependencies: [
        .external(name: "CryptoCoreKit")
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
        .external(name: "CryptoCoreKit")
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
        .external(name: "CryptoCoreKit")
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
        .target(name: "AsyncFeature"),
        .target(name: "GrpcFeature"),
    ]
)

let project = Project(
    name: "CryptoCoreApp",
    targets: [app, marketsFeature, asyncFeature, grpcFeature]
)
