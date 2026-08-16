// swift-tools-version: 6.2
import PackageDescription

// Vendored copy of swift-protobuf's runtime library (Sources/SwiftProtobuf
// from https://github.com/apple/swift-protobuf, tag 1.30.0 — the same
// version ElizaProtoKit/generate.sh pins its protoc-gen-swift build to).
// See LICENSE.txt for the original Apache 2.0 license.
//
// Vendored instead of pulled in as a remote SPM dependency specifically to
// drop the `resources: [.copy("PrivacyInfo.xcprivacy")]` declaration the
// upstream target carries: any SPM target with `resources:` gets an
// auto-synthesized Xcode resource-bundle companion target on generation,
// and Tuist's PackageSettings.targetSettings can't reach that synthesized
// target to set its deployment target - it resets to iOS 12.0 (invalid on
// current Simulator SDKs) on every `tuist generate`. This vendored target
// declares no resources, so no bundle target gets synthesized and the
// whole class of bug disappears rather than needing a documented manual
// patch after every generate.
let package = Package(
    name: "SwiftProtobufVendored",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SwiftProtobuf", targets: ["SwiftProtobuf"])
    ],
    targets: [
        .target(name: "SwiftProtobuf")
    ]
)
