// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CLNestedSlide",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CLNestedSlide",
            targets: ["CLNestedSlide"]
        ),
    ],
    targets: [
        .target(
            name: "CLNestedSlide",
            path: "CLNestedSlide/CLNestedSlideView"
        )
    ],
    swiftLanguageVersions: [.v5]
) 