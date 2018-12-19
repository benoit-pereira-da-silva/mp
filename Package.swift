// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "mp",
    dependencies: [
        // You can checkout locally the module to work on multiple modules at the same time.
        // For example to work on MPLib : .package(path:"../MPLib"),
        // + swift package generate-xcodeproj
        .package(url:"https://github.com/benoit-pereira-da-silva/CommandLine", from: "4.0.5"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Globals", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/Tolerance", from: "1.0.0"),
        .package(url:"https://github.com/benoit-pereira-da-silva/HTTPClient", from: "1.0.0"),
        .package(path:"../MPLib"),
        //.package(url:"https://github.com/benoit-pereira-da-silva/MPLib", from: "1.0.0"),
        //.package(path:"../NavetLib"),
        .package(url:"https://github.com/benoit-pereira-da-silva/NavetLib", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "mp",
            dependencies: ["CommandLineKit", "Globals","Tolerance", "HTTPClient", "MPLib","NavetLib"]),
        .testTarget(
            name: "mpTests",
            dependencies: ["mp"]),
    ]
)
