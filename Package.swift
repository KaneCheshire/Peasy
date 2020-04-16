// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let peasyLibrary: Product = .library(name: "Peasy", targets: ["Peasy"])
let peasyTarget: Target = .target(name: peasyLibrary.name)

extension Target {
    
    var testTarget: Target {
        return .testTarget(name: name + "Tests", dependencies: [.target(name: name)])
    }
    
}

let package = Package(
    name: peasyLibrary.name,
    platforms: [.iOS(.v8), .watchOS(.v2), .tvOS(.v9), .macOS(.v10_10)],
    products: [peasyLibrary],
    targets: [peasyTarget, peasyTarget.testTarget]
)

