// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription


fileprivate enum Stage {
    case development
    case release
}

fileprivate struct Configuration{

    // Turn to .release before to merge on master
    static let stage:Stage = .release

    static var dependencies: [PackageDescription.Package.Dependency]{
        switch self.stage{
        case .development:
            return [
                .package(path:"../CommandLine"),
                .package(path:"../HMAC"),
                .package(path:"../Globals"),
                .package(path:"../Tolerance"),
                .package(path:"../HTTPClient"),
                .package(path:"../MPLib"),
                .package(path:"../NavetLib")
            ]
        case .release:
            return [
                .package(url:"https://github.com/benoit-pereira-da-silva/CommandLine", from: "4.0.5"),
                .package(url:"https://github.com/benoit-pereira-da-silva/HMAC", from: "1.0.0"),
                .package(url:"https://github.com/benoit-pereira-da-silva/Globals", from: "1.0.0"),
                .package(url:"https://github.com/benoit-pereira-da-silva/Tolerance", from: "1.0.0"),
                .package(url:"https://github.com/benoit-pereira-da-silva/HTTPClient", from: "1.0.0"),
                .package(url:"https://github.com/benoit-pereira-da-silva/MPLib", from: "1.0.0"),
                .package(url:"https://github.com/benoit-pereira-da-silva/NavetLib", from: "1.0.0"),
            ]
        }
    }
}

let package = Package(
    name: "mp",
    dependencies:
        Configuration.dependencies
    ,
    targets: [
        .target(
            name: "mp",
            dependencies: ["CommandLineKit","HMAC", "Globals","Tolerance", "HTTPClient", "MPLib","NavetLib"]),
        .testTarget(
            name: "mpTests",
            dependencies: ["mp"]),
    ]
)
