// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistory",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipboardHistory",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("Carbon", .when(platforms: [.macOS])),
                .linkedFramework("ServiceManagement", .when(platforms: [.macOS])),
                .linkedFramework("LinkPresentation", .when(platforms: [.macOS]))
            ]
        )
    ]
)
