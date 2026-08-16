// swift-tools-version: 6.2
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    baseSettings: .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
    targetSettings: [
        "SwiftProtobuf": ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"],
        "SwiftProtobuf_SwiftProtobuf": ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"],
    ]
)
#endif

let package = Package(
    name: "CryptoCoreAppDependencies",
    platforms: [.iOS(.v26)],
    dependencies: [
        .package(path: "../../CryptoCoreKitSDK"),
        .package(path: "../../ElizaProtoKit"),
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.9.1"),
    ]
)
