// swift-tools-version: 6.2
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    baseSettings: .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
    targetSettings: [
        // Swinject's own Package.swift declares .iOS(.v12) — without this
        // override, every `tuist generate` regenerates its derived
        // .xcodeproj with IPHONEOS_DEPLOYMENT_TARGET back at 12.0.
        "Swinject": ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"],
        // TCA's macro plugin target declares macOS 13, below SwiftSyntax's
        // (its own dependency) minimum of macOS 15 on this toolchain.
        "ComposableArchitectureMacros": ["MACOSX_DEPLOYMENT_TARGET": "15.0"],
        "ComposableArchitecture": ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"],
        // SwiftProtobuf no longer appears here: it's vendored (see
        // ../../SwiftProtobufVendored) specifically to avoid the same
        // class of bug on its synthesized resource-bundle target, which
        // targetSettings can't reach by name at all.
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
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.17.0"),
    ]
)
