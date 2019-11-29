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
    products: [peasyLibrary],
    targets: [peasyTarget, peasyTarget.testTarget]
)

