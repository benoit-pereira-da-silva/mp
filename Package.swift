// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mp",
    dependencies: [
        // You can checkout locally the module to fix multi module issues.
        // For example
        //.package(path:"../MPLib"),
        .package(url:"https://github.com/benoit-pereira-da-silva/CommandLine", from: "4.0.5"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Globals", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Tolerance", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/HTTPClient", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/MPLib", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/NavetLib", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "mp",
            dependencies: ["CommandLineKit", "Globals","Tolerance", "HTTPClient", "MPLib","NavetLib"]),
        .testTarget(
            name: "mpTests",
            dependencies: ["mp"]),
    ]
)
