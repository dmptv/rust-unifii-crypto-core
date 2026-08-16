import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")

// Wraps the raw UniFFI-generated bindings + .xcframework behind a module
// boundary. Feature modules import CryptoCoreKit, never the xcframework
// directly — the generated FfiConverter/RustBuffer plumbing stays contained
// to this one module.
let cryptoCoreKit = Target.target(
    name: "CryptoCoreKit",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.example.cryptocoreapp.cryptocorekit",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    sources: ["Modules/CryptoCoreKit/Sources/**"],
    dependencies: [
        .xcframework(path: "../crypto_core/crypto_core.xcframework")
    ]
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
        .target(name: "CryptoCoreKit")
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
        .target(name: "CryptoCoreKit")
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
    ]
)

let project = Project(
    name: "CryptoCoreApp",
    targets: [app, cryptoCoreKit, marketsFeature, asyncFeature]
)
