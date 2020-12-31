// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Feedbacks",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Feedbacks",
            targets: ["Feedbacks"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/combine-schedulers.git", .exact(Version("0.1.2"))),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Feedbacks",
            dependencies: []),
        .testTarget(
            name: "FeedbacksTests",
            dependencies: ["Feedbacks", .product(name: "CombineSchedulers", package: "combine-schedulers")]),
    ]
)
